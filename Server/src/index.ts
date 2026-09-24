import { createServer, type Server } from 'node:http';
import { Monitor } from 'node-screenshots';
import sharp from 'sharp';
import ngrok from '@ngrok/ngrok';
import dotenv from 'dotenv';

dotenv.config();

const FPS = 5;
const SCREEN_RESOLUTION = {
  x: 80, //64,
  y: 45 //36
};
const COLOR_THRESHOLD = 10; // Bigger number = more "compressed" image

const PORT = Number(process.env.PORT ?? 8080);
const MAX_QUEUED_FRAMES = 600;

const PROTOCOL_MAGIC = 0x31424656;
const PROTOCOL_VERSION = 2;
const FRAME_RECORD_BYTES = 8;
const PROTOCOL_HEADER_BYTES = 16;
const PIXEL_COUNT = SCREEN_RESOLUTION.x * SCREEN_RESOLUTION.y;

const firstMonitor = Monitor.all()[0];
if (!firstMonitor) {
    throw new Error('No monitor found');
};

const monitor = firstMonitor;

let frameQueue: Buffer[] = [];
let httpServer: Server | undefined;
let ngrokListener: Awaited<ReturnType<typeof ngrok.forward>> | undefined;
let shuttingDown = false;
let needsFullFrame = true;

console.log(
    'Monitor:',
    monitor.id(),
    monitor.name(),
    [monitor.x(), monitor.y(), monitor.width(), monitor.height()],
    monitor.rotation(),
    monitor.scaleFactor(),
    monitor.frequency(),
    monitor.isPrimary(),
);


async function getFrame() {
  const img = monitor.captureImageSync();
  const buffer = await sharp(img.toRawSync(), { raw: { width: img.width, height: img.height, channels: 4 } })
    .resize(SCREEN_RESOLUTION.x, SCREEN_RESOLUTION.y)
    .flop()
    .removeAlpha()
    .toBuffer();

  return buffer;
};

let previousFrame: Buffer | null = null;

function encodeFrameDelta(currentFrame: Buffer): Buffer {
  const frame = Buffer.allocUnsafe(PIXEL_COUNT * FRAME_RECORD_BYTES);
  let offset = 0;

  for (let i = 0; i < currentFrame.length; i += 3) {
    const changed =
      needsFullFrame ||
      !previousFrame ||
      Math.abs(currentFrame[i] - previousFrame[i]) > COLOR_THRESHOLD ||
      Math.abs(currentFrame[i + 1] - previousFrame[i + 1]) > COLOR_THRESHOLD ||
      Math.abs(currentFrame[i + 2] - previousFrame[i + 2]) > COLOR_THRESHOLD;

    if (!changed) {
      continue;
    }

    frame.writeUInt32LE(i / 3, offset);
    frame.writeUInt8(currentFrame[i], offset + 4);
    frame.writeUInt8(currentFrame[i + 1], offset + 5);
    frame.writeUInt8(currentFrame[i + 2], offset + 6);
    frame.writeUInt8(0, offset + 7);
    offset += FRAME_RECORD_BYTES;
  }

  previousFrame = Buffer.from(currentFrame);
  needsFullFrame = false;
  return frame.subarray(0, offset);
}

if (FPS <= 0) {
  throw new Error('FPS must be greater than 0');
}

if (PORT <= 0 || PORT > 65535) {
  throw new Error('PORT must be between 1 and 65535');
}

const FRAME_INTERVAL_MS = 1000 / FPS;

console.log(
  `Capture config: ${FPS} FPS, ${SCREEN_RESOLUTION.x}x${SCREEN_RESOLUTION.y}`
);

let isCapturing = false;

function enqueueFrame(frame: Buffer): void {
  frameQueue.push(frame);
  if (frameQueue.length > MAX_QUEUED_FRAMES) {
    frameQueue.splice(0, frameQueue.length - MAX_QUEUED_FRAMES);
  }
}

function startHttpServer(): Promise<void> {
  httpServer = createServer((request, response) => {
    if (request.method !== 'GET' || request.url?.split('?')[0] !== '/') {
      response.writeHead(404);
      response.end();
      return;
    }

    const requestUrl = new URL(request.url, `http://${request.headers.host ?? 'localhost'}`);
    if (requestUrl.searchParams.get('clear') === '1') {
      frameQueue = [];
      previousFrame = null;
      needsFullFrame = true;
    }

    const header = Buffer.alloc(PROTOCOL_HEADER_BYTES);
    header.writeUInt32LE(PROTOCOL_MAGIC, 0);
    header.writeUInt16LE(PROTOCOL_VERSION, 4);
    header.writeUInt16LE(SCREEN_RESOLUTION.x, 6);
    header.writeUInt16LE(SCREEN_RESOLUTION.y, 8);
    header.writeUInt32LE(frameQueue.length, 10);

    const framePayloads = frameQueue.map((frame) => {
      const length = Buffer.alloc(4);
      length.writeUInt32LE(frame.length, 0);
      return Buffer.concat([length, frame]);
    });
    frameQueue = [];

    const body = Buffer.concat([header, ...framePayloads]);
    response.writeHead(200, {
      'Content-Type': 'application/octet-stream',
      'Cache-Control': 'no-store',
      'Access-Control-Allow-Origin': '*',
    });
    response.end(body);
  });

  return new Promise((resolve, reject) => {
    httpServer?.once('error', reject);
    httpServer?.listen(PORT, '0.0.0.0', resolve);
  });
}

async function startNgrok(): Promise<void> {
  const ngrokOptions = {
    addr: PORT,
    ...(process.env.NGROK_AUTHTOKEN
      ? { authtoken: process.env.NGROK_AUTHTOKEN }
      : {}),
  };
  ngrokListener = await ngrok.forward(ngrokOptions);
  console.log(`NGROK TUNNEL READY: ${ngrokListener.url()}`);
}

async function shutdown(): Promise<void> {
  if (shuttingDown) return;
  shuttingDown = true;
  console.log('\nShutting down...');

  if (ngrokListener) {
    await ngrokListener.close();
  }
  await ngrok.kill();

  await new Promise<void>((resolve) => {
    if (!httpServer) {
      resolve();
      return;
    }
    httpServer.close(() => resolve());
  });
}

setInterval(async () => {
  if (isCapturing) {
    return;
  }

  isCapturing = true;
  try {
    const frame = await getFrame();
    enqueueFrame(encodeFrameDelta(frame));
  } catch (error) {
    console.error('Failed to capture frame:', error);
  } finally {
    isCapturing = false;
  }
}, FRAME_INTERVAL_MS);

void (async () => {
  try {
    await startHttpServer();
    console.log(`Local server running at http://localhost:${PORT}`);
    await startNgrok();
  } catch (error) {
    console.error('Failed to start HTTP server or ngrok:', error);
    await shutdown();
    process.exitCode = 1;
  }
})();

process.once('SIGINT', () => void shutdown());
process.once('SIGTERM', () => void shutdown());
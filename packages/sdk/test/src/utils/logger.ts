import * as fs from 'fs';
import * as path from 'path';
import { PassThrough } from 'stream';
import * as winston from 'winston';

const logDirectory = path.join(__dirname, '../../../logs');
export const processedLogCache: any[] = [];

const processedLogFilePath = path.join(logDirectory, 'staking-processed.json');

function initProcessedLogCache(filePath = processedLogFilePath) {
  console.log('Loading log messages into cache...');
  processedLogCache.length = 0; // Clear existing cache
  if (!fs.existsSync(filePath)) {
    return;
  }
  const fileData = fs.readFileSync(filePath, 'utf-8');
  fileData
    .trim()
    .split('\n')
    .forEach((line) => {
      if (line) {
        processedLogCache.push(JSON.parse(line));
      }
    });
}

const logStream = new PassThrough();
logStream.on('data', (chunk) => {
  processedLogCache.push(JSON.parse(chunk.toString())); // Parse and store each log entry
});

const logger = winston.createLogger({
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.printf(({ timestamp, level, message }) => `${timestamp} [${level.toUpperCase()}]: ${message}`),
  ),
  transports: [
    new winston.transports.Console({ level: 'warn' }),
    new winston.transports.File({ filename: path.join(logDirectory, 'staking.log'), level: 'info' }),
  ],
});

function createProcessedLogger(filePath = processedLogFilePath) {
  const logStream = new PassThrough();
  logStream.on('data', (chunk) => {
    processedLogCache.push(JSON.parse(chunk.toString())); // Store each log entry in the cache
  });

  return winston.createLogger({
    level: 'info',
    format: winston.format.combine(winston.format.timestamp(), winston.format.json()),
    transports: [
      new winston.transports.File({ filename: filePath, level: 'info' }),
      new winston.transports.Stream({ stream: logStream, level: 'info' }), // In-memory transport
    ],
  });
}

initProcessedLogCache();

const processedLogger = createProcessedLogger();

export { logger, processedLogger, initProcessedLogCache, createProcessedLogger };

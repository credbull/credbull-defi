import * as fs from 'fs';
import * as path from 'path';
import { PassThrough } from 'stream';
import * as winston from 'winston';

const logDirectory = path.join(__dirname, '../../../logs');
export const processedLogCache: any[] = [];

const processedLogFilePath = path.join(logDirectory, 'staking-processed.json');

// Initialize logMessages from file, if it exists
function initProcessedLogCache() {
  console.log('Loading log messages into cache...');
  if (!fs.existsSync(processedLogFilePath)) {
    return;
  }

  const fileData = fs.readFileSync(processedLogFilePath, 'utf-8');
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
  level: 'debug', // Set the default log level

  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.printf(({ timestamp, level, message }) => `${timestamp} [${level.toUpperCase()}]: ${message}`),
  ),
  transports: [
    new winston.transports.Console(), // Log to console
    new winston.transports.File({ filename: path.join(logDirectory, 'staking.log'), level: 'info' }),
  ],
});

const processedLogger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json(), // Structured logging in JSON format
  ),
  transports: [
    new winston.transports.File({ filename: processedLogFilePath, level: 'info' }),
    new winston.transports.Stream({ stream: logStream, level: 'info' }), // In-memory transport
  ],
});

initProcessedLogCache();

export { logger, processedLogger };

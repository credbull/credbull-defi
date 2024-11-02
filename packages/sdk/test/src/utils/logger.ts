import * as path from 'path';
import * as winston from 'winston';

const logDirectory = path.join(__dirname, '../../../logs');

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
    new winston.transports.File({ filename: path.join(logDirectory, 'staking-processed.json'), level: 'info' }),
  ],
});

export { logger, processedLogger };

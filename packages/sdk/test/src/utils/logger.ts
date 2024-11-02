import * as path from 'path';
import * as winston from 'winston';

const logFilePath = path.join(__dirname, '../../../logs/staking.log');

const logger = winston.createLogger({
  level: 'debug', // Set the default log level

  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.printf(({ timestamp, level, message }) => `${timestamp} [${level.toUpperCase()}]: ${message}`),
  ),
  transports: [
    new winston.transports.Console(), // Log to console
    new winston.transports.File({ filename: logFilePath, level: 'info' }),
  ],
});

export default logger;

import { Request, Response, NextFunction } from 'express';

export function requestFilter(req: Request, res: Response, next: NextFunction): void {
  next();
}

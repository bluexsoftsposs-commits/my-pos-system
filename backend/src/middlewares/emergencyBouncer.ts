import { Request, Response, NextFunction } from 'express';

export function emergencyBouncer(req: Request, res: Response, next: NextFunction): void {
  next();
}

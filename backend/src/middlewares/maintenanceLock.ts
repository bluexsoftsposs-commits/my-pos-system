import { Request, Response, NextFunction } from 'express';
import { isMaintenanceMode } from '../services/emergencyState';

export function maintenanceLock(emergencyPrefix: string) {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!isMaintenanceMode()) {
      next();
      return;
    }

    if (req.path.startsWith(emergencyPrefix)) {
      next();
      return;
    }

    res.status(503).json({ error: 'System under maintenance. Only emergency access is available.' });
  };
}

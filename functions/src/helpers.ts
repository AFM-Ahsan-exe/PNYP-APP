import * as crypto from 'crypto';
import * as admin from 'firebase-admin';

export function hmacSha256(cnic: string, secret: string): string {
  return crypto.createHmac('sha256', secret).update(cnic).digest('hex');
}

export function generateMemberId(year: number): string {
  const sequence = String(Math.floor(Math.random() * 900000) + 100000);
  return `PYNP-${year}-${sequence}`;
}

export function computeAge(dateOfBirth: admin.firestore.Timestamp | undefined): number {
  if (!dateOfBirth) return 0;
  const dob = dateOfBirth.toDate();
  const today = new Date();
  let age = today.getFullYear() - dob.getFullYear();
  const monthDiff = today.getMonth() - dob.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
    age--;
  }
  return age;
}

export function validateCnicFormat(cnic: string): boolean {
  const digits = cnic.replace(/-/g, '');
  return /^\d{13}$/.test(digits);
}

export function normalizeCnic(cnic: string): string {
  return cnic.replace(/-/g, '');
}

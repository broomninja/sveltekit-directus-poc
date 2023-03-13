import { z } from 'zod';
import { PUBLIC_FORM_PASSWORD_LEN_MIN } from '$env/static/public';
import validator from 'validator';

//
// System wide constraints used for both client and server side validation
//

const PASSWORD_LEN_MIN = PUBLIC_FORM_PASSWORD_LEN_MIN ?? 6;

export const FirstNameConstraint = z
    .string({ required_error: 'First name is required' })
    .trim()
    .min(1, { message: 'First name is required' })
    .max(50, { message: 'First name must be less than 50 characters' });

export const LastNameConstraint = z
    .string({ required_error: 'Last name is required' })
    .trim()
    .min(1, { message: 'Last name is required' })
    .max(50, { message: 'Last name must be less than 50 characters' });

export const EmailConstraint = z
    .string({ required_error: 'Email is required' })
    .trim()
    .min(1, { message: 'Email is required' })
    .max(128, { message: 'Email must be less than 128 characters' })
    .email({ message: 'Email must be a valid email address' });

export const PasswordConstraint = z
    .string({ required_error: 'Password is required' })
    .trim()
    .min(PASSWORD_LEN_MIN, {
        message: 'Password must be at least ' + PUBLIC_FORM_PASSWORD_LEN_MIN + ' characters',
    })
    .max(128, { message: 'Password must be less than 128 characters' });

export const ConfirmPasswordConstraint = z
    .string({ required_error: 'Confirm password is required' })
    .trim()
    .min(PASSWORD_LEN_MIN, {
        message: 'Confirm password must be at least ' + PUBLIC_FORM_PASSWORD_LEN_MIN + ' characters',
    })
    .max(128, { message: 'Confirm password must be less than 128 characters' });

// only allows relative urls for redirection
export const RelativeUrlConstraint = z
    .string()
    .trim()
    .optional()
    .refine((url: string | undefined) => {
        if (!url) return true;
        const fullUrlWithProtocal = validator.isURL(url, {
            require_protocol: true,
            require_host: true,
           });
        const fullOrRelativeUrl = validator.isURL(url, {
            require_protocol: false,
            require_host: false,
           });
        return !fullUrlWithProtocal && fullOrRelativeUrl;
}, 'Invalid Url');
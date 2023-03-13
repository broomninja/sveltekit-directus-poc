import { z } from 'zod';

//
// Form input constraints used for both client and server side validation
//
// For Feedback, Comment forms
// 

export const IdConstraint = z
    .string({ required_error: 'ID is required' })
    .uuid( { message: 'Not a valid ID' } );

export const TitleConstraint = z
    .string({ required_error: 'Title is required' })
    .trim()
    .min(1, { message: 'Title is required' })
    .max(250, { message: 'Title must be less than 250 characters' });

export const FeedbackContentConstraint = z
    .string({ required_error: 'Content is required' })
    .trim()
    .min(1, { message: 'Content is required' })
    .max(1000, { message: 'Content must be less than 1000 characters' });

export const CommentContentConstraint = z
    .string({ required_error: 'Content is required' })
    .trim()
    .min(1, { message: 'Content is required' })
    .max(500, { message: 'Content must be less than 128 characters' });

export const SlugConstraint = z
    .string({ required_error: 'Slug is required' })
    .trim()
    .min(1, { message: 'Slug is required' })
    .max(250, { message: 'Slug must be less than 250 characters' });
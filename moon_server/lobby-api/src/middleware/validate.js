const { body, validationResult } = require('express-validator');

/**
 * Middleware — runs validation results and short-circuits with 400 if any fail.
 */
function validate(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array().map(e => e.msg) });
  }
  next();
}

/**
 * Rules for POST /auth/register
 */
const registerRules = [
  body('username')
    .trim()
    .isLength({ min: 3, max: 32 }).withMessage('Username must be 3–32 characters')
    .matches(/^[a-zA-Z0-9_]+$/).withMessage('Username may only contain letters, numbers, and underscores'),
  body('password')
    .isLength({ min: 8, max: 128 }).withMessage('Password must be 8–128 characters'),
  body('email')
    .optional({ checkFalsy: true })
    .isEmail().withMessage('Invalid email address')
    .normalizeEmail(),
];

/**
 * Rules for POST /auth/login
 */
const loginRules = [
  body('username').trim().notEmpty().withMessage('Username is required').escape(),
  body('password').notEmpty().withMessage('Password is required'),
];

/**
 * Rules for POST /chat/global and /chat/friend
 */
const chatRules = [
  body('content')
    .trim()
    .isLength({ min: 1, max: 500 }).withMessage('Message must be 1–500 characters')
    .escape(),
];

/**
 * Rules for POST /rooms/create
 */
const roomCreateRules = [
  body('title')
    .optional()
    .trim()
    .isLength({ max: 64 }).withMessage('Title max 64 characters')
    .escape(),
  body('max_players')
    .optional()
    .isInt({ min: 1, max: 4 }).withMessage('max_players must be 1–4'),
];

/**
 * Rules for POST /admin/ban
 */
const banRules = [
  body('user_id').isUUID().withMessage('Invalid user_id'),
  body('reason').optional().trim().isLength({ max: 256 }).withMessage('Reason max 256 chars').escape(),
  body('expires_at').optional().isISO8601().withMessage('expires_at must be ISO 8601 date'),
];

module.exports = {
  validate,
  registerRules,
  loginRules,
  chatRules,
  roomCreateRules,
  banRules,
};

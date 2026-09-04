class HttpsError extends Error {
    constructor(code, message) {
        super(message);
        this.code = code;
        this.name = 'HttpsError';
    }
}
module.exports = {
    https: {
        HttpsError,
        onCall: jest.fn((handler) => handler),
    },
    logger: {
        error: jest.fn(),
        warn: jest.fn(),
    },
};

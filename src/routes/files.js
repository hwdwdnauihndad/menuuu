const fs = require('fs')
const path = require('path')
const util = require('util')
const pipeline = util.promisify(require('stream').pipeline)

async function routes(fastify, options) {
    fastify.post('/upload', async (req, reply) => {
        const data = await req.file()

        if (!data) {
            return reply.code(400).send({ error: 'No file uploaded' })
        }

        const filename = data.filename
        const savePath = path.join(__dirname, '../../uploads', filename)

        await pipeline(data.file, fs.createWriteStream(savePath))

        return {
            status: 'success',
            url: `/files/${filename}`
        }
    })

    fastify.get('/list', async (req, reply) => {
        const uploadsDir = path.join(__dirname, '../../uploads')
        try {
            const files = await fs.promises.readdir(uploadsDir)
            return { files }
        } catch (err) {
            return { files: [] }
        }
    })
}

module.exports = routes

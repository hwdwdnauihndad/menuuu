const fastify = require('fastify')({ logger: true })
const path = require('path')
const fs = require('fs')

fastify.register(require('@fastify/multipart'))
fastify.register(require('@fastify/static'), {
    root: path.join(__dirname, '../uploads'),
    prefix: '/files/',
})

fastify.register(require('@fastify/static'), {
    root: path.join(__dirname, '../public'),
    prefix: '/public/',
    decorateReply: false
})

fastify.register(require('./routes/files'))

const start = async () => {
    try {
        const uploadsDir = path.join(__dirname, '../uploads')
        if (!fs.existsSync(uploadsDir)) {
            fs.mkdirSync(uploadsDir)
        }
        await fastify.listen({ port: 3001, host: '0.0.0.0' })
    } catch (err) {
        fastify.log.error(err)
        process.exit(1)
    }
}

start()

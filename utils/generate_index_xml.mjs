import {readdirSync, statSync, writeFileSync} from 'fs'
import {join} from 'path'

const tpl = '<?xml version="1.0" encoding="utf-8" standalone="no"?>\r\n<configurations>\r\n%entries%\r\n</configurations>'

const baseFolder = process.cwd() + '/xml_configurations'
console.log('baseFolder: ' + baseFolder)

/** @type string[] */
const result = []

async function iterateDirectory(path) {
    const files = await readdirSync(path)

    for(const file of files) {
        /** @type string */
        const filePath = join(path, file)
        const stat = await statSync(filePath)

        if (stat.isDirectory()) {
            await iterateDirectory(filePath)
        } else if (stat.isFile() && file !== 'index.xml') {
            const relativePath = filePath.substring(baseFolder.length + 1).replace('\\', '/')
            result.push(`\t<entry>${relativePath}</entry>`)
        }
    }
}

async function writeOutResult() {
    const entries = result.join('\r\n')
    const xml = tpl.replace('%entries%', entries)
    await writeFileSync(`${baseFolder}/index.xml`, xml)
}

await iterateDirectory(baseFolder)
await writeOutResult()
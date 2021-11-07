import * as Streams from 'streams'
import * as Path from 'path'
import yargs from 'yargs'
import { Keychain } from 'keychain'
import type { Arguments } from 'yargs/types'

const program = yargs()
  .scriptName('secrets')
  .version(false)
  .help()
  .option('help', { alias: 'h', description: 'Show help' })
  .strictCommands()
  .completion()

program.command(
  'save [filename]',
  'save a secret file in keychain',
  {
    key: {
      alias: 'k',
      description: 'Name of keychain item',
      type: 'string',
    },
  },
  withErrorHandling(async (args: Arguments) => {
    const filename = args.filename as string | undefined
    let contents: string
    if (filename == null || filename === '-') {
      if (args.key == null)
        throw new Error('--key is required when reading from stdin')

      contents = new TextDecoder().decode(await Streams.readAll(Deno.stdin))
    } else {
      await canReadFile(filename)

      contents = new TextDecoder().decode(
        await Deno.readFile(Path.resolve(filename)),
      )
    }

    const keychain = await getKeychain()

    const key =
      args.key ?? `~/${Path.relative(Deno.env.get('HOME') ?? '/', filename!)}`

    try {
      await keychain.deleteGenericPassword({
        account: '',
        service: key,
        type: 'note',
      })
    } catch {
      // ignore
    }

    await keychain.addGenericPassword({
      account: '',
      service: key,
      password: contents,
      kind: 'secure note',
      type: 'note',
      applications: false,
    })
  }),
)

program.command(
  'load [filename]',
  'load keychain item',
  {
    key: {
      alias: 'k',
      description: 'Name of keychain item',
      type: 'string',
    },
  },
  withErrorHandling(async (args: Arguments) => {
    const filename = args.filename as string | undefined

    if (filename == null || filename === '-') {
      if (args.key == null)
        throw new Error('--key is required when reading from stdin')
    }

    const keychain = await getKeychain()
    const HOME = Deno.env.get('HOME') ?? '/'
    const key = args.key ?? `~/${Path.relative(HOME, filename!)}`

    const contents = await keychain.findGenericPassword({
      account: '',
      service: key,
      type: 'note',
    })

    if (filename == null || filename === '-') {
      console.log(contents)
    } else {
      const outfile = await Deno.realPath(filename.replace(/^[~]/, HOME))
      console.log({ key, outfile })
      await Deno.mkdir(Path.dirname(outfile), { recursive: true })
      await Deno.remove(outfile)
      await Deno.writeFile(outfile, new TextEncoder().encode(contents), {
        mode: 0o400,
      })
    }
  }),
)

try {
  await program.parseAsync(Deno.args)
  if (Deno.args.length === 0) program.showHelp()
} catch (error) {
  if (error instanceof Error) {
    console.error(error.message)
  } else {
    console.error(error)
  }

  program.exit(1)
}

// deno-lint-ignore no-explicit-any
function withErrorHandling<T extends (...args: any[]) => any>(value: T): T {
  return ((...args: unknown[]) => {
    try {
      const result = value(...args)
      if (result instanceof Promise) {
        return result.catch((error) => {
          console.error(error.message)
          Deno.exit(1)
        })
      }

      return result
    } catch (error) {
      console.error(error.message)
      Deno.exit(1)
    }
  }) as T
}

async function canReadFile(filename: string): Promise<void> {
  const status = await Deno.permissions.request({
    name: 'read',
    path: Path.resolve(filename),
  })

  if (status.state !== 'granted') {
    throw new Error(`Cannot read ${filename}`)
  }
}

async function getKeychain(): Promise<Keychain> {
  const status = await Deno.permissions.request({
    name: 'env',
    variable: 'SECRETS_PATH',
  })

  if (status.state === 'granted') {
    const filename = Deno.env.get('SECRETS_PATH')
    if (filename != null) return new Keychain(filename)
  }

  return new Keychain(
    Path.join(Deno.env.get('HOME') ?? '~', 'Documents/Secrets.keychain-db'),
  )
}

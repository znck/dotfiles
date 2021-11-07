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

    const keychain = await getKeychain()
    const HOME = Deno.env.get('HOME') ?? '/'
    if (filename == null || filename === '-') {
      if (args.key == null)
        throw new Error('--key is required when reading from stdin')

      contents = new TextDecoder().decode(await Streams.readAll(Deno.stdin))
    } else {
      const infile = Path.resolve(Deno.cwd(), filename.replace(/^[~]/, HOME))

      await canReadFile(infile)
      contents = new TextDecoder().decode(await Deno.readFile(infile))
    }

    const key = args.key ?? `~/${Path.relative(HOME, filename!)}`

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
  'ls',
  'list keychain items',
  {},
  withErrorHandling(async () => {
    const keychain = await getKeychain()
    const items = await keychain.getItems()

    console.log(...items.map((item) => item.service))
  }),
)

program.command(
  'rm',
  'remove keychain items',
  {
    key: {
      type: 'string',
      required: true,
      alias: 'k',
      description: 'Name of key to delete',
    },
  },
  withErrorHandling(async (args: Arguments) => {
    const keychain = await getKeychain()
    const key = args.key

    await keychain.deleteGenericPassword({
      account: '',
      service: key,
      type: 'note',
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
      const outfile = Path.resolve(Deno.cwd(), filename.replace(/^[~]/, HOME))
      await canWriteFile(outfile)
      try {
        await Deno.remove(outfile)
      } finally {
        await Deno.writeFile(outfile, new TextEncoder().encode(contents), {
          mode: 0o400,
        })
      }
    }
  }),
)

try {
  await program.parseAsync(Deno.args)
  if (Deno.args.length === 0) program.showHelp()
} catch (error) {
  if (error instanceof Error) {
    console.error(error)
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
    path: filename,
  })

  if (status.state !== 'granted') {
    throw new Error(`Cannot read ${filename}`)
  }
}

async function canWriteFile(filename: string): Promise<void> {
  const status = await Deno.permissions.request({
    name: 'write',
    path: filename,
  })

  if (status.state !== 'granted') {
    throw new Error(`Cannot write ${filename}`)
  }
}

async function getKeychain(): Promise<Keychain> {
  const permissionHome = await Deno.permissions.request({
    name: 'env',
    variable: 'HOME',
  })
  const permissionSecretsPath = await Deno.permissions.request({
    name: 'env',
    variable: 'SECRETS_PATH',
  })

  if (permissionHome.state !== 'granted') {
    throw new Error('HOME variable is required')
  }

  if (permissionSecretsPath.state === 'granted') {
    const filename = Deno.env.get('SECRETS_PATH')
    if (filename != null) return new Keychain(filename)
  }

  return new Keychain(
    Path.join(Deno.env.get('HOME') ?? '~', 'Documents/Secrets.keychain-db'),
  )
}

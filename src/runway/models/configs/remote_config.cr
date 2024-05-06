require "yaml"

class RemoteConfig
  include YAML::Serializable

  # @return [String, nil] The authentication method to use when connecting to the remote server.
  # Options include: `login`, `publickey`, or `agent`
  # see: https://github.com/spider-gazelle/ssh2.cr/blob/1e3fc7da3cc5d7689dea6b57e50e1713050f84fd/src/session.cr#L149-L177
  property auth : String?

  # @return [String] The type hostname / ip address of the remote server to SSH into.
  property host : String?

  # @return [Int32] The port to use when connecting to the remote server.
  property port : Int32?

  # @return [String] The username to use when connecting to the remote server.
  property username : String?

  # @return [String, nil] The ENVIRONMENT VARIABLE, to fetch the password from for the remote server.
  # User's should absolutely not store passwords in the configuration file.
  property password : String?

  # @return [String, nil] The path to the private key to use when connecting to the remote server.
  # this value is required if the auth is set to `publickey` by the underlying library
  # see: https://github.com/spider-gazelle/ssh2.cr/blob/1e3fc7da3cc5d7689dea6b57e50e1713050f84fd/src/session.cr#L159-L163
  property private_key_path : String?

  # @return [String, nil] The path to the public key to use when connecting to the remote server.
  property public_key_path : String?

  # @return [String, nil] The ENVIRONMENT VARIABLE, to fetch the passphrase from for the remote server when using a private key.
  # this value is not required if the private key is not encrypted with a passphrase
  property passphrase : String?

  # @return [String, nil] A "string" to search for in the remote command output to determine if the command was successful.
  property success_string : String?
end

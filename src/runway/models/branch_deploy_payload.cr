require "json"
require "../lib/to_h"

# https://github.com/github/branch-deploy/blob/f9cc91d1f3b53149b3abcb582f2844993cd9277d/docs/deployment-payload.md
class BranchDeployPayload
  include ToH
  include JSON::Serializable

  property type : String?
  property sha : String?
  property params : String?
  property parsed_params : JSON::Any?
  property github_run_id : Int64?
  property initial_comment_id : Int64?
  property initial_reaction_id : Int64?
  property deployment_started_comment_id : Int64?
  property timestamp : String?
  property commit_verified : Bool?
  property actor : String?
  property stable_branch_used : Bool?
end

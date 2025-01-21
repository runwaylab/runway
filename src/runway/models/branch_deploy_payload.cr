require "json"

class BranchDeployPayload
  include JSON::Serializable

  property type : String?
  property sha : String?
  property params : String?
  property parsed_params : JSON::Any?
  property github_run_id : Int32?
  property initial_comment_id : Int32?
  property initial_reaction_id : Int32?
  property deployment_started_comment_id : Int32?
  property timestamp : String?
  property commit_verified : Bool?
  property actor : String?
  property stable_branch_used : Bool?
end

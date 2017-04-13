require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
APPLICATION_NAME = 'Gmail API Ruby Quickstart'
CLIENT_SECRETS_PATH = 'client_secret.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             "gmail-ruby-quickstart.yaml")
SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(
    client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(
      base_url: OOB_URI)
    puts "Open the following URL in the browser and enter the " +
         "resulting code after authorization"
    puts url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI)
  end
  credentials
end

# Initialize the API
service = Google::Apis::GmailV1::GmailService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

# Show the user's labels
user_id = 'me'
result = service.list_user_messages(user_id, q: 'in:inbox')


unless result.messages
  puts "No messages"
  exit 0
end

FROM_EMAIL = 'notifications@github.com'
MERGED_STRING = 'Merged #'

result.messages.each do |message|
  message_full = service.get_user_message(user_id, message.id)
  payload = message_full.payload
  next if payload.headers.select { |header| header.name == 'From' && header.value.include?("<#{FROM_EMAIL}>") }.empty?
  next unless payload.body.data.include?(MERGED_STRING)
  modify_thread_request_object = Google::Apis::GmailV1::ModifyThreadRequest.new(remove_label_ids: ['Inbox'])
  service.modify_thread(user_id, message.thread_id, modify_thread_request_object)
end

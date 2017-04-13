function gmail_archive_merged_pull_requests() {
  echorun cd ~/projects/gmail_archive_merged_github_pull_requests || return $?
  echorun bi || return $?
  echorun bundle exec ruby process.rb || return $?
}

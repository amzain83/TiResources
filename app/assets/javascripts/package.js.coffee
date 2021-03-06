auth = if GITHUB_AUTH? then GITHUB_AUTH else {}

loadProject = (user_project, cb) ->
  $.ajax
    url: "https://api.github.com/repos/#{user_project}"
    data: auth
    dataType: "jsonp"
    success: (data) ->
      cb data

loadBranch = (user_project, branch, cb) ->
  $.ajax
    url: "https://api.github.com/repos/#{user_project}/branches/#{branch}"
    data: auth
    dataType: "jsonp"
    success: (data) ->
      cb data

loadTree = (user_project, tree_sha, cb) ->
  $.ajax
    url: "https://api.github.com/repos/#{user_project}/git/trees/#{tree_sha}"
    data: auth
    dataType: "jsonp"
    success: (data) ->
      cb data

loadBlob = (user_project, sha, cb) ->
  $.ajax
    url: "https://api.github.com/repos/#{user_project}/git/blobs/#{sha}"
    data: auth
    dataType: "jsonp"
    success: (data) ->
      cb data




GITHUB_STRIP_RE = /(^.+:\/\/github.com\/)|(\.git\s*$)/gi

$ ->
  $('.close-link').click ->
    (expire = new Date()).setTime(new Date().getTime() + 1e12)
    document.cookie = "hideBanner=1;expires=#{expire.toGMTString()}"
    $('.banner').hide()

  $('.guest .new_module').each ->
    href = $(this).attr 'href'
    href = "/login" + "?redirect_to=" + href
    $(this).popover
      title: "Please sign in first."
      html: true
      content: $('.login-link').clone().attr('href', href)
      placement: 'bottom'
  .click ->
    return false
  
  valid = ->
    $('#package_github_repo').val().match(/^[a-z0-9][a-z0-9-]+\/[a-z0-9_\.-]+$/i)

  $('#package_github_repo').bind 'keyup change', ->
    $('.load-from-github').toggleClass('disabled', !valid())
    if $(this).val().match(GITHUB_STRIP_RE)
      $(this).val $(this).val().replace(GITHUB_STRIP_RE, '')
  .keyup()

  $('.load-from-github').click ->
    return unless valid()
    UP = $('#package_github_repo').val()

    loadProject UP, (project) ->
      $('#package_name').val(project.data.name)
      $('#package_homepage').val(project.data.homepage)
      $('#package_description').val(project.data.description)
      $('#package_tag_list').focus()

      loadBranch UP, project.data.master_branch, (branch) ->
        loadTree UP, branch.data.commit.commit.tree.sha, (tree) ->
          readme = (file for file in tree.data.tree when file.path.match(/^README/))[0]
          if readme
            loadBlob UP, readme.sha, (readme) ->
              $('#package_readme_markdown').val Base64.decode(readme.data.content)

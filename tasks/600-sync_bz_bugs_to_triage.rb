# Override the task configuration in the profile:
#   600-sync_bz_bugs_to_triage:
#     color: 'amber'
#     tag: 'Triage'
#     bz_filter:
#       component: 'Hammer'
#
# By default the untriaged bugs matching the filter
# are turned into tasks on Backlog. It can be configured
# if new tasks are created at the top or bottom of the Backlog.
# The tasks are tagged 'Triage'. The tag and color can be
# changed in the config.

default_configuration = {
  'color' => 'amber',
  'tag' => 'Triage',
  'create_on_top' => true,
  'bz_filter' => {
    'bug_status' => ['NEW', 'ASSIGNED'],
    'query_format' => 'advanced',
    'classification' => 'Red Hat',
    'product' => 'Red Hat Satellite 6',
    'component' => 'My Component',
    'keywords' => 'Tracking-',
    'keywords_type' => 'nowords',
    'f2' => 'component',
    'f3' => 'flagtypes.name',
    'o2' => 'notsubstring',
    'o3' => 'notsubstring',
    'v2' => 'Doc',
    'v3' => 'devel_triaged+',
  }}

task_configuration = default_configuration.deep_merge(task_configuration)

existing_triage_tasks = project.current_tasks(filter: "tag:\"#{task_configuration['tag']}\"").map do |task|
  task.bugzilla_ids.map(&:to_i)
end.flatten.uniq

Bugzilla.search(task_configuration['bz_filter']).each do |bz|
  logger.info "Processing ##{bz.id} #{bz.summary}"
  if existing_triage_tasks.include?(bz.id)
    logger.debug "Skipping ##{bz.id} triage task, it's already there"
  else
    logger.info "Creating new triage task for ##{bz.id}"
    task = KanboardTask.create(
      'title' => "BZ ##{bz.id}: #{bz.summary}",
      'project_id' => project.id,
      'color_id' => task_configuration['color'],
      'description' => 'Change ownership of the task to yourself and triage the BZ',
      'tags' => [task_configuration['tag']]
    )
    task.create_link(bz.url, 'Bugzilla')
    task.move_to_top if task_configuration['create_on_top']
  end
end

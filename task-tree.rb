#!/usr/bin/env ruby

require 'rubygems'
require 'commander/import'
require 'tty-prompt'
require 'byebug'
require 'tree'
require 'json'
require 'tty'

program :name, 'tasky-trackery'
program :version, '0.0.1'
program :description, 'Lets you keep track of what your doing and your stack, allowing you to traverse back when tasks are complete'

command :start do |c|
  c.syntax = 'tasky-trackery start [options]'
  c.summary = ''
  c.description = ''
  c.example 'start --output=file.json', 'run tasky with a custom output / store file'
  c.option '--output=<output>', 'Set a custom output file'
  c.option '--figlet-font=<figlet_font>', 'Path to figlet font to use'
  c.action do |args, options|
    # Do something or c.when_called Tasky-trackery::Commands::Start
    t = Tasky.new(options)
    t.start
  end
end


class Tasky
  def initialize(options)
    @output = options.output || 'default.json'
    @font_path = options.figlet_font || './fonts/larry3d'
    @prompt = TTY::Prompt.new
    @tree_root = Tree::TreeNode.new('__', '__')
    @current_node = @tree_root
    @screen = TTY::Screen.new
  end

  def start
    restore_state
    print_current

    action = :quit
    loop do
      action = @prompt.expand('Next action?') do |q|
        q.choice key: 'a', name: 'add', value: :add
        q.choice key: 'u', name: 'up', value: :up
        q.choice key: 'd', name: 'down', value: :down
        q.choice key: 'n', name: 'next', value: :next
        q.choice key: 'p', name: 'previous', value: :previous
        q.choice key: 'P', name: 'print', value: :print
        q.choice key: 'c', name: 'complete', value: :complete
        q.choice key: 'q', name: 'quit', value: :quit
        q.choice key: 'x', name: 'quit without saving', value: :exit
        q.choice key: 's', name: 'start pommodoro timer', value: :pommo
        q.choice key: 'l', name: 'clean display', value: :clean
      end
      handle_action(action)
      break if action == :quit || action == :exit
    end
    save_state if action == :quit
  end

  def handle_action(action)
    case action
    when :clean
      print_current
      @prompt.keypress('_')
    when :add
      prompt_and_add_task
      print_current
      save_state
    when :up
      move_up
      print_current
    when :down
      move_down
      print_current
    when :print
      print_tree
      print_current
    when :complete
      set_as_complete
      print_current
      save_state
    when :previous
      move_previous
      print_current
    when :next
      move_next
      print_current
    when :pommo
      start_pommo
    end
  end

  def start_pommo
    minutes = @prompt.ask('how many minutes?', convert: :int)
    bar = TTY::ProgressBar.new('[:bar]', total: minutes*6)
    (minutes*6).times do
      sleep(10)
      bar.advance(1)
      # TODO: check for quit or pause?
    end
  end

  def print_tree
    @tree_root.print_tree
  end

  def select_with_menu
    selected = @prompt.select("Current level:") do |menu|
      @current_node.children.each do |c|
        menu.choice c.name, c
      end
    end
    @current_node = selected
  end

  def set_as_complete
    @current_node.content = 'complete'
    move_next
  end

  def move_up
    @current_node = @current_node.parent if !@current_node.parent.nil?
  end

  def move_down
    @current_node = @current_node.first_child unless @current_node.first_child.nil?
    if @current_node.content == 'complete'
      move_up unless move_next || move_previous
    end
  end

  def move_previous(prev=@current_node)
    return false if prev.is_only_child? || prev.is_first_sibling?
    prev = prev.previous_sibling
    if prev.content == 'complete'
      prev = move_previous(prev)
    else
      @current_node = prev
    end
    true
  end

  def move_next(nxt=@current_node)
    return false if nxt.is_only_child? || nxt.is_last_sibling?
    nxt = nxt.next_sibling
    if nxt.content == 'complete'
      nxt = move_next(nxt)
    else
      @current_node = nxt
    end
    true
  end

  def prompt_and_add_task
    new_task = @prompt.ask('what to add?')
    return if new_task.nil? || new_task.empty?
    new_node = Tree::TreeNode.new(new_task, new_task)
    @current_node << new_node
    @current_node = new_node
  end

  def print_current
    draw_task(@current_node.content)
  end

  def draw_task(task)
    width = @screen.width
    text = `figlet -f #{@font_path} -c -w #{width} #{task}`
    puts text
  end

  def save_state
    File.write(@output, @tree_root.to_json)
  end

  def restore_state
    return unless File.exist?(@output)
    data = File.read(@output)
    parsed_data = JSON.parse(data)
    @tree_root = load_tree(parsed_data)
    @current_node = @tree_root
  end

  def load_tree(json_hash)
    node = Tree::TreeNode.new(json_hash['name'], json_hash['content'])
    json_hash['children'].each { |h| node << load_tree(h) } unless json_hash['children'].nil?
    node
  end
end


require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end


helpers do
  def is_completed?(list)
    list[:todos].all? { |todo| todo[:completed] == true } && list[:todos].size > 0
  end
  
  def format_complete(list)
    is_completed?(list) ? "complete" : nil
  end
  
  def todos_remaining(list)
    todos_left = list[:todos].count { |todo| todo[:completed] == false }
    total_todos = list[:todos].size
    "#{todos_left} / #{total_todos}"
  end
  
  def sort_lists(lists)
    lists.sort_by { |list| is_completed?(list) ? 1 : 0 }
  end
  
  def sort_todos(todos)
    todos.sort_by { |todo| todo[:completed] == true ? 1 : 0 }
  end
  
  def find_list_index(name)
    session[:lists].each_with_index do |list, index| 
      return index if list[:name] == name
    end
  end
  
  def find_todo_index(name)
    @todos.each_with_index do |todo, index|
      return index if todo[:name] == name
    end
  end
end

get "/" do
  redirect "/lists"
end

# View all lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Return error message if name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
   
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# View specific todo list
get "/lists/:id" do
  id = params[:id].to_i
  @list = session[:lists][id]
  @name = @list[:name]
  @todos = @list[:todos]
  erb :todos, layout: :layout
end

def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo name must be between 1 and 100 characters."
  end
end

# Add todo to specific list
post "/lists/:id/todos" do
  id = params[:id].to_i
  @list = session[:lists][id]
  todo = params[:todo].strip
  @name = @list[:name]
  @todos = @list[:todos]
  
  error = error_for_todo(todo)
  
  if error
    session[:error] = error
    erb :todos, layout: :layout
  else
    @list[:todos] << { name: todo, completed: false }
    session[:success] = "Todo successfully added."
    redirect "/lists/#{id}"
  end
end

# Edit existing todo list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]
  @name = @list[:name]
  erb :edit_list, layout: :layout
end

# Delete exisiting todo list
post "/lists/:id/destroy" do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

post "/lists/:id" do
  list_name = params[:list_name].strip
  id = params[:id].to_i 
  @list = session[:lists][id]
  @name = @list[:name]
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
    # redirect "/lists/#{id}/edit"
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{id}"
  end
end

post "/lists/:id/todos/:todo_id/destroy" do
  id = params[:id].to_i
  todo_id = params[:todo_id].to_i
  @list = session[:lists][id]
  @name = @list[:name]
  @todos = @list[:todos]
  @todos.delete_at(todo_id)
  session[:success] = "The todo item has been deleted."
  redirect "/lists/#{id}"
end

# Update status of todo item
post "/lists/:id/todos/:todo_id/toggle" do
  id = params[:id].to_i
  todo_id = params[:todo_id].to_i
  @list = session[:lists][id]
  @name = @list[:name]
  @todos = @list[:todos]
  is_completed = params[:completed] == "true"
  @todos[todo_id][:completed] = is_completed
  session[:success] = "The todo item has been updated."
  redirect "/lists/#{id}"
end

# Mark all todos as complete for specific list
post "/lists/:id/check_all" do
  id = params[:id].to_i
  @list = session[:lists][id]
  @name = @list[:name]
  @todos = @list[:todos]
  @todos.each { |todo| todo[:completed] = true }
  session[:success] = "The todo items have all been completed."
  redirect "lists/#{id}"
end

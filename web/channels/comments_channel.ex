defmodule Discuss.CommentsChannel do
  use Discuss.Web, :channel

  alias Discuss.{Topic, Comment}

  def join("comments:" <> topic_id, _params, socket) do
    topic_id = String.to_integer(topic_id)
    topic = Topic
      |> Repo.get(topic_id)
      |> Repo.preload(comments: [:user])

    {:ok, %{comments: topic.comments}, assign(socket, :topic, topic)}
  end

  def handle_in(name, %{"content" => content}, socket) do
    topic = socket.assigns.topic

    changeset = topic
    |> build_assoc(:comments, user_id: socket.assigns.user_id)
    # |> assoc([:comments, :users])
    # |> build_assoc(:users)
    |> Comment.changeset(%{content: content})

    # changeset = %{ changeset, user_id: topic.user_id }
    # changeset = Map.put(changeset, "user_id", socket.assigns.topic.user_id)

    case Repo.insert(changeset) do
      {:ok, comment} ->
        broadcast!(socket, "comments:#{socket.assigns.topic.id}:new", %{comment: comment})
        {:reply, :ok, socket}
      {:error, reason} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

end

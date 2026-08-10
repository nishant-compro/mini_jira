const apiBase = import.meta.env.VITE_API_URL || ""

async function request(path, options = {}) {
  const response = await fetch(`${apiBase}/api${path}`, {
    credentials: "include",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      ...options.headers
    },
    ...options,
    body: options.body && JSON.stringify(options.body)
  })

  const data = await response.json().catch(() => ({}))
  if (!response.ok) {
    throw new Error((data.errors || ["Something went wrong."]).join(" "))
  }
  return data
}

export const api = {
  getProjects: () => request("/projects"),
  getProject: (id) => request(`/projects/${id}`),
  createProject: (project) => request("/projects", { method: "POST", body: { project } }),
  getTicket: (projectId, ticketId) => request(`/projects/${projectId}/tickets/${ticketId}`),
  getTicketForm: (projectId, ticketId = null) => request(ticketId ? `/projects/${projectId}/tickets/${ticketId}/edit` : `/projects/${projectId}/tickets/new`),
  createTicket: (projectId, ticket) => request(`/projects/${projectId}/tickets`, { method: "POST", body: { ticket } }),
  updateTicket: (projectId, ticketId, ticket) => request(`/projects/${projectId}/tickets/${ticketId}`, { method: "PATCH", body: { ticket } }),
  deleteTicket: (projectId, ticketId) => request(`/projects/${projectId}/tickets/${ticketId}`, { method: "DELETE" }),
  addComment: (projectId, ticketId, body) => request(`/projects/${projectId}/tickets/${ticketId}/comments`, { method: "POST", body: { comment: { body } } }),
  updateComment: (projectId, ticketId, commentId, body) => request(`/projects/${projectId}/tickets/${ticketId}/comments/${commentId}`, { method: "PATCH", body: { comment: { body } } }),
  deleteComment: (projectId, ticketId, commentId) => request(`/projects/${projectId}/tickets/${ticketId}/comments/${commentId}`, { method: "DELETE" }),
  createUser: (user) => request("/users", { method: "POST", body: { user } }),
  switchUser: (userId) => request("/users/switch", { method: "POST", body: { user_id: userId } })
}

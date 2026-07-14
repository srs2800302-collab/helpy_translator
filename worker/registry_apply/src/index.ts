interface Env {
  GITHUB_OWNER: string;
  GITHUB_REPOSITORY: string;
  GITHUB_DOCUMENT_PATH: string;
  GITHUB_BRANCH: string;
}

export default {
  fetch(request: Request, env: Env): Response {
    const url = new URL(request.url);

    if (request.method === 'GET' && url.pathname === '/health') {
      return jsonResponse(200, {
        status: 'ok',
        service: 'registry-studio-apply',
        repository: `${env.GITHUB_OWNER}/${env.GITHUB_REPOSITORY}`,
        branch: env.GITHUB_BRANCH,
        documentPath: env.GITHUB_DOCUMENT_PATH,
      });
    }

    return jsonResponse(404, {
      error: 'Not found.',
    });
  },
} satisfies ExportedHandler<Env>;

function jsonResponse(
  status: number,
  body: Record<string, unknown>,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
    },
  });
}

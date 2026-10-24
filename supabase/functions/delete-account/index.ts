// supabase/functions/delete-account/index.ts
// TASKI · PARTE 10 — Edge Function para eliminación controlada de cuenta, Storage y metadatos
import { createClient } from 'npm:@supabase/supabase-js@2';

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return Response.json(
      { error: 'Method not allowed' },
      { status: 405 },
    );
  }

  const token = req.headers.get('Authorization');
  if (!token?.startsWith('Bearer ')) {
    return Response.json(
      { error: 'Unauthorized' },
      { status: 401 },
    );
  }

  const url = Deno.env.get('SUPABASE_URL')!;
  const anon = Deno.env.get('SUPABASE_ANON_KEY')!;
  const service = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  // 1. Verificar identidad del solicitante mediante su JWT (nunca aceptar user_id del cliente)
  const userClient = createClient(url, anon, {
    global: { headers: { Authorization: token } },
  });

  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user) {
    return Response.json(
      { error: 'Unauthorized' },
      { status: 401 },
    );
  }

  const userId = data.user.id;
  const admin = createClient(url, service);

  try {
    // 2. Recuperar y eliminar objetos del bucket privado 'task-attachments' en lotes de 100
    const { data: attachments, error: qError } = await admin
      .from('task_attachments')
      .select('storage_path')
      .eq('user_id', userId);

    if (qError) throw qError;

    const attachmentPaths = (attachments ?? [])
      .map((x: { storage_path?: unknown }) => x.storage_path)
      .filter((x: unknown): x is string => typeof x === 'string' && x.length > 0);

    for (let i = 0; i < attachmentPaths.length; i += 100) {
      const batch = attachmentPaths.slice(i, i + 100);
      const { error: removeError } = await admin.storage
        .from('task-attachments')
        .remove(batch);
      if (removeError) throw removeError;
    }

    // 3. Recuperar y eliminar objetos del bucket 'avatars' bajo el prefijo UUID del usuario
    const { data: avatarFiles, error: listAvatarError } = await admin.storage
      .from('avatars')
      .list(userId, { limit: 100 });

    if (listAvatarError) throw listAvatarError;

    if (avatarFiles && avatarFiles.length > 0) {
      const avatarPaths = avatarFiles
        .filter((f: { name?: string }) => f.name && f.name.length > 0)
        .map((f: { name: string }) => `${userId}/${f.name}`);

      if (avatarPaths.length > 0) {
        const { error: removeAvatarError } = await admin.storage
          .from('avatars')
          .remove(avatarPaths);
        if (removeAvatarError) throw removeAvatarError;
      }
    }

    // 4. Eliminar identidad en Auth (las tablas profiles, categories, tasks, subtasks y task_attachments tienen ON DELETE CASCADE)
    const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
    if (deleteError) {
      return Response.json(
        { error: 'No se pudo borrar la cuenta' },
        { status: 500 },
      );
    }

    return Response.json(
      {
        status: 'deleted',
        user_id: userId,
        removed_attachments: attachmentPaths.length,
      },
      { status: 200 },
    );
  } catch (err) {
    return Response.json(
      { error: `Error durante la limpieza de cuenta: ${err}` },
      { status: 500 },
    );
  }
});

// ---------------------------------------------------------------------------
// CONFIGURAÇÃO CENTRAL — edite aqui para atualizar o número em todo o site.
// ---------------------------------------------------------------------------

// Formato internacional, só dígitos: código do país + DDD + número.
export const WHATSAPP_NUMBER = "5567991105206";

export function buildWhatsAppLink(message = "") {
  const base = `https://wa.me/${WHATSAPP_NUMBER}`;
  if (!message) return base;
  return `${base}?text=${encodeURIComponent(message)}`;
}

// Distância total (em vh) da experiência cinematográfica controlada por
// scroll. Único lugar a ajustar para deixar o movimento mais rápido/lento.
export const CINEMA_SCROLL_VH = 650;

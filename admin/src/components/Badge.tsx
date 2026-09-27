import { OrderStatus } from '../lib/types';

export function OrderStatusBadge({ status }: { status: OrderStatus }) {
  const configs: Record<OrderStatus, { label: string; bg: string; text: string; dot: string }> = {
    pending_payment: {
      label: 'Chờ thanh toán',
      bg: 'bg-amber-500/10 border-amber-500/30',
      text: 'text-amber-400',
      dot: 'bg-amber-400',
    },
    paid: {
      label: 'Đã thanh toán',
      bg: 'bg-blue-500/10 border-blue-500/30',
      text: 'text-blue-400',
      dot: 'bg-blue-400',
    },
    processing: {
      label: 'Đang xử lý',
      bg: 'bg-indigo-500/10 border-indigo-500/30',
      text: 'text-indigo-400',
      dot: 'bg-indigo-400',
    },
    shipping: {
      label: 'Đang giao hàng',
      bg: 'bg-cyan-500/10 border-cyan-500/30',
      text: 'text-cyan-400',
      dot: 'bg-cyan-400',
    },
    completed: {
      label: 'Hoàn tất',
      bg: 'bg-emerald-500/10 border-emerald-500/30',
      text: 'text-emerald-400',
      dot: 'bg-emerald-400',
    },
    cancelled: {
      label: 'Đã hủy',
      bg: 'bg-rose-500/10 border-rose-500/30',
      text: 'text-rose-400',
      dot: 'bg-rose-400',
    },
  };

  const c = configs[status] || configs.pending_payment;

  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold border ${c.bg} ${c.text}`}
    >
      <span className={`w-1.5 h-1.5 rounded-full ${c.dot}`} />
      {c.label}
    </span>
  );
}

export function ReasonBadge({ reason }: { reason: string }) {
  const mapping: Record<string, { label: string; color: string }> = {
    admin_restock: { label: 'Nhập kho', color: 'text-emerald-400 bg-emerald-500/10 border-emerald-500/30' },
    admin_correction: { label: 'Hiệu chỉnh kho', color: 'text-amber-400 bg-amber-500/10 border-amber-500/30' },
    order_created: { label: 'Khách đặt hàng', color: 'text-blue-400 bg-blue-500/10 border-blue-500/30' },
    order_cancelled: { label: 'Hủy đơn hoàn kho', color: 'text-purple-400 bg-purple-500/10 border-purple-500/30' },
  };

  const item = mapping[reason] || { label: reason, color: 'text-slate-400 bg-slate-800 border-slate-700' };

  return (
    <span className={`px-2 py-0.5 rounded text-[11px] font-medium border ${item.color}`}>
      {item.label}
    </span>
  );
}

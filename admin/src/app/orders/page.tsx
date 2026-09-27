'use client';

import { useState, useEffect, useCallback } from 'react';
import { Header } from '../../components/Header';
import { OrderStatusBadge } from '../../components/Badge';
import { ChangeOrderStatusModal } from '../../components/ChangeOrderStatusModal';
import { fetchAdminOrders, updateOrderStatus } from '../../lib/api';
import { Order, OrderStatus } from '../../lib/types';
import {
  ShoppingBag,
  Filter,
  CheckCircle2,
  AlertCircle,
  Truck,
  CreditCard,
  User,
  MapPin,
  Calendar,
} from 'lucide-react';

const STATUS_TABS: { label: string; value: OrderStatus | 'all' }[] = [
  { label: 'Tất cả đơn', value: 'all' },
  { label: 'Chờ thanh toán', value: 'pending_payment' },
  { label: 'Đã thanh toán', value: 'paid' },
  { label: 'Đang xử lý', value: 'processing' },
  { label: 'Đang giao hàng', value: 'shipping' },
  { label: 'Đã hoàn tất', value: 'completed' },
  { label: 'Đã hủy', value: 'cancelled' },
];

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<OrderStatus | 'all'>('all');

  // Updating status modal
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [newStatus, setNewStatus] = useState<OrderStatus>('processing');
  const [statusNote, setStatusNote] = useState('');
  const [updating, setUpdating] = useState(false);
  const [feedback, setFeedback] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const loadOrders = useCallback(async () => {
    setLoading(true);
    try {
      const data = await fetchAdminOrders(activeTab === 'all' ? undefined : activeTab);
      setOrders(data);
    } finally {
      setLoading(false);
    }
  }, [activeTab]);

  useEffect(() => {
    loadOrders();
  }, [loadOrders]);

  async function handleUpdateStatus() {
    if (!selectedOrder) return;
    setUpdating(true);
    setFeedback(null);
    try {
      await updateOrderStatus(selectedOrder.id, newStatus, statusNote);
      setFeedback({ text: 'Cập nhật trạng thái đơn hàng thành công!', type: 'success' });
      setOrders((prev) =>
        (Array.isArray(prev) ? prev : []).map((o) =>
          o.id === selectedOrder.id ? { ...o, status: newStatus } : o
        )
      );
      setSelectedOrder(null);
      setStatusNote('');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Lỗi khi cập nhật trạng thái đơn hàng';
      setFeedback({ text: msg, type: 'error' });
    } finally {
      setUpdating(false);
    }
  }

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Quản lý Đơn hàng"
        subtitle="Theo dõi và chuyển đổi trạng thái quy trình đơn hàng MenShop"
        onRefresh={loadOrders}
      />

      <div className="p-8 space-y-6 flex-1">
        {/* Status Filter Tabs */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 bg-slate-900/60 p-3 rounded-2xl border border-slate-800">
          <Filter className="w-4 h-4 text-slate-400 ml-2 mr-1" />
          {STATUS_TABS.map((tab) => (
            <button
              key={tab.value}
              onClick={() => setActiveTab(tab.value)}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all shrink-0 cursor-pointer ${
                activeTab === tab.value
                  ? 'bg-amber-500 text-slate-950 shadow-sm'
                  : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Feedback message */}
        {feedback && (
          <div
            className={`p-3 rounded-xl text-xs font-semibold flex items-center gap-2 ${
              feedback.type === 'success'
                ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30'
                : 'bg-rose-500/10 text-rose-400 border border-rose-500/30'
            }`}
          >
            {feedback.type === 'success' ? (
              <CheckCircle2 className="w-4 h-4" />
            ) : (
              <AlertCircle className="w-4 h-4" />
            )}
            <span>{feedback.text}</span>
          </div>
        )}

        {/* Orders list */}
        <div className="space-y-4">
          {loading ? (
            <div className="p-16 text-center text-slate-500 text-sm">Đang tải đơn hàng...</div>
          ) : orders.length === 0 ? (
            <div className="p-16 text-center text-slate-500 text-sm">
              Không tìm thấy đơn hàng nào ở bộ lọc này
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-4">
              {orders.map((ord) => (
                <div
                  key={ord.id}
                  className="bg-slate-900/60 border border-slate-800 rounded-2xl p-5 hover:border-slate-700 transition-all space-y-4 shadow-sm"
                >
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-800/60">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-amber-400 font-bold">
                        <ShoppingBag className="w-5 h-5" />
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-mono font-bold text-white text-sm">#{ord.code}</span>
                          <OrderStatusBadge status={ord.status} />
                        </div>
                        <div className="flex items-center gap-3 text-[11px] text-slate-400 mt-0.5">
                          <span className="flex items-center gap-1">
                            <Calendar className="w-3 h-3" />
                            {new Date(ord.createdAt).toLocaleString('vi-VN')}
                          </span>
                          <span>•</span>
                          <span className="font-mono text-slate-300">ID: {ord.id.slice(0, 8)}...</span>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <span className="text-base font-extrabold text-white font-mono">
                        {ord.total.toLocaleString('vi-VN')} đ
                      </span>
                      <button
                        onClick={() => {
                          setSelectedOrder(ord);
                          setNewStatus(ord.status);
                        }}
                        className="px-3 py-1.5 rounded-xl text-xs font-semibold bg-slate-800 hover:bg-slate-700 text-amber-400 border border-slate-700 transition-all flex items-center gap-1.5 cursor-pointer"
                      >
                        <Truck className="w-3.5 h-3.5" />
                        Đổi trạng thái
                      </button>
                    </div>
                  </div>

                  {/* Customer info & Item list */}
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-3 border-t border-slate-800/60 text-xs">
                    <div className="space-y-1">
                      <span className="text-slate-400 font-semibold flex items-center gap-1">
                        <User className="w-3 h-3 text-slate-500" /> Người nhận:
                      </span>
                      <p className="text-slate-200 font-medium">{ord.shippingAddress.name}</p>
                      <p className="text-slate-400">{ord.shippingAddress.phone}</p>
                    </div>

                    <div className="space-y-1">
                      <span className="text-slate-400 font-semibold flex items-center gap-1">
                        <MapPin className="w-3 h-3 text-slate-500" /> Địa chỉ giao hàng:
                      </span>
                      <p className="text-slate-300 leading-relaxed">{ord.shippingAddress.address}</p>
                      {ord.shippingAddress.note && (
                        <p className="text-amber-400 text-[11px]">
                          * Ghi chú: {ord.shippingAddress.note}
                        </p>
                      )}
                    </div>

                    <div className="space-y-1">
                      <span className="text-slate-400 font-semibold flex items-center gap-1">
                        <CreditCard className="w-3 h-3 text-slate-500" /> Thanh toán:
                      </span>
                      <p className="text-slate-200 uppercase font-semibold">
                        {ord.paymentMethod === 'vnpay' ? 'Thanh toán trực tuyến VNPay' : 'Thanh toán khi nhận hàng (COD)'}
                      </p>
                      <p className="text-slate-400 text-[11px]">
                        Gồm {ord.items.length} mặt hàng trong giỏ
                      </p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Change Status Modal */}
      <ChangeOrderStatusModal
        selectedOrder={selectedOrder}
        newStatus={newStatus}
        statusNote={statusNote}
        updating={updating}
        onClose={() => setSelectedOrder(null)}
        onStatusChange={setNewStatus}
        onNoteChange={setStatusNote}
        onSave={handleUpdateStatus}
      />
    </div>
  );
}

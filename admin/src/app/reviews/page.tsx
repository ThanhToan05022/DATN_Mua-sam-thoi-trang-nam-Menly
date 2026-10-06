'use client';

import { useState, useEffect, useCallback } from 'react';
import { Header } from '../../components/Header';
import { fetchAdminReviews, deleteAdminReview, Review } from '../../lib/review-api';
import { Star, Trash2, CheckCircle2, AlertCircle } from 'lucide-react';

export default function ReviewsPage() {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [msg, setMsg] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const loadReviews = useCallback(async () => {
    setLoading(true);
    try {
      const data = await fetchAdminReviews(1, 50);
      setReviews(data.items);
    } catch (e: any) {
      setMsg({ text: e.message || 'Lỗi tải đánh giá', type: 'error' });
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadReviews();
  }, [loadReviews]);

  const handleDelete = async (id: string) => {
    if (!confirm('Bạn có chắc chắn muốn xóa đánh giá này?')) return;
    try {
      await deleteAdminReview(id);
      setReviews((prev) => prev.filter((r) => r.id !== id));
      setMsg({ text: 'Đã xóa đánh giá vi phạm', type: 'success' });
    } catch (e: any) {
      setMsg({ text: e.message || 'Lỗi khi xóa đánh giá', type: 'error' });
    }
  };

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Quản lý Đánh giá"
        subtitle="Xem danh sách đánh giá của khách hàng và xóa các đánh giá vi phạm"
        onRefresh={loadReviews}
      />

      <div className="p-8 space-y-6 flex-1">
        {msg && (
          <div
            className={`p-3.5 rounded-xl text-xs font-semibold flex items-center gap-2 ${
              msg.type === 'success'
                ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30'
                : 'bg-rose-500/10 text-rose-400 border border-rose-500/30'
            }`}
          >
            {msg.type === 'success' ? <CheckCircle2 className="w-4 h-4" /> : <AlertCircle className="w-4 h-4" />}
            <span>{msg.text}</span>
          </div>
        )}

        <div className="bg-slate-900/60 rounded-2xl border border-slate-800 overflow-hidden">
          {loading ? (
            <div className="p-8 flex justify-center">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-amber-500"></div>
            </div>
          ) : reviews.length === 0 ? (
            <div className="p-12 text-center text-slate-400">Không có đánh giá nào</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-900/80 border-b border-slate-800 text-xs font-semibold text-slate-400 uppercase tracking-wider">
                    <th className="p-4 pl-6">Khách hàng</th>
                    <th className="p-4">Đánh giá</th>
                    <th className="p-4">Nội dung</th>
                    <th className="p-4">Ngày đăng</th>
                    <th className="p-4 pr-6 text-right">Thao tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/50">
                  {reviews.map((r) => (
                    <tr key={r.id} className="hover:bg-slate-800/30 transition-colors">
                      <td className="p-4 pl-6">
                        <div className="text-sm font-semibold text-slate-200">
                          {r.user?.name || 'Khách'}
                        </div>
                        <div className="text-xs text-slate-500">{r.user?.email || 'N/A'}</div>
                      </td>
                      <td className="p-4">
                        <div className="flex items-center gap-1">
                          {Array.from({ length: 5 }).map((_, i) => (
                            <Star
                              key={i}
                              className={`w-4 h-4 ${
                                i < r.rating ? 'text-amber-400 fill-amber-400' : 'text-slate-700'
                              }`}
                            />
                          ))}
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="text-sm text-slate-300 max-w-md truncate">
                          {r.comment || <span className="text-slate-600 italic">Không có nhận xét</span>}
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="text-sm text-slate-400">
                          {new Date(r.createdAt).toLocaleDateString('vi-VN')}
                        </div>
                      </td>
                      <td className="p-4 pr-6 text-right">
                        <button
                          onClick={() => handleDelete(r.id)}
                          className="p-2 text-rose-400 hover:bg-rose-500/10 rounded-lg transition-colors"
                          title="Xóa đánh giá vi phạm"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

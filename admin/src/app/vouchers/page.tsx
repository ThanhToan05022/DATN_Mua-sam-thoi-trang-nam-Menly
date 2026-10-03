'use client';

import { useState, useEffect, useCallback } from 'react';
import { Header } from '../../components/Header';
import {
  fetchAdminVouchers,
  createVoucher,
  updateVoucher,
  deleteVoucher,
} from '../../lib/api';
import { Voucher, CreateVoucherInput, DiscountType } from '../../lib/types';
import {
  Ticket,
  Plus,
  Search,
  CheckCircle2,
  AlertCircle,
  Percent,
  DollarSign,
  Calendar,
  Layers,
  Trash2,
  Edit2,
  X,
  Clock,
  Sparkles,
  ToggleLeft,
  ToggleRight,
} from 'lucide-react';

export default function VouchersPage() {
  const [vouchers, setVouchers] = useState<Voucher[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState<'all' | DiscountType>('all');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all');

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingVoucher, setEditingVoucher] = useState<Voucher | null>(null);
  const [msg, setMsg] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  // Form states
  const [formData, setFormData] = useState<CreateVoucherInput>({
    code: '',
    title: '',
    discountType: 'percentage',
    discountValue: 10,
    minOrderValue: 0,
    maxDiscount: null,
    usageLimit: 100,
    startDate: new Date().toISOString().slice(0, 10),
    endDate: new Date(Date.now() + 86400000 * 30).toISOString().slice(0, 10),
    isActive: true,
  });
  const [submitting, setSubmitting] = useState(false);

  const loadVouchers = useCallback(async () => {
    setLoading(true);
    try {
      const data = await fetchAdminVouchers();
      setVouchers(data);
    } catch (e: unknown) {
      setMsg({ text: (e as Error).message || 'Không thể tải danh sách voucher', type: 'error' });
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadVouchers();
  }, [loadVouchers]);

  const openCreateModal = () => {
    setEditingVoucher(null);
    setFormData({
      code: '',
      title: '',
      discountType: 'percentage',
      discountValue: 10,
      minOrderValue: 200000,
      maxDiscount: 50000,
      usageLimit: 100,
      startDate: new Date().toISOString().slice(0, 10),
      endDate: new Date(Date.now() + 86400000 * 30).toISOString().slice(0, 10),
      isActive: true,
    });
    setIsModalOpen(true);
  };

  const openEditModal = (v: Voucher) => {
    setEditingVoucher(v);
    setFormData({
      code: v.code,
      title: v.title,
      discountType: v.discountType,
      discountValue: v.discountValue,
      minOrderValue: v.minOrderValue,
      maxDiscount: v.maxDiscount ?? null,
      usageLimit: v.usageLimit,
      startDate: v.startDate.slice(0, 10),
      endDate: v.endDate.slice(0, 10),
      isActive: v.isActive,
    });
    setIsModalOpen(true);
  };

  const handleToggleActive = async (v: Voucher) => {
    try {
      const nextActive = !v.isActive;
      await updateVoucher(v.id, { isActive: nextActive });
      setVouchers((prev) =>
        prev.map((item) => (item.id === v.id ? { ...item, isActive: nextActive } : item))
      );
      setMsg({
        text: `Đã ${nextActive ? 'kích hoạt' : 'tạm dừng'} mã "${v.code}"!`,
        type: 'success',
      });
    } catch (e: unknown) {
      setMsg({ text: (e as Error).message || 'Lỗi khi cập nhật trạng thái', type: 'error' });
    }
  };

  const handleDelete = async (v: Voucher) => {
    if (!confirm(`Bạn có chắc chắn muốn xóa mã giảm giá "${v.code}"?`)) return;
    try {
      await deleteVoucher(v.id);
      setVouchers((prev) => prev.filter((item) => item.id !== v.id));
      setMsg({ text: `Đã xóa mã "${v.code}" thành công!`, type: 'success' });
    } catch (e: unknown) {
      setMsg({ text: (e as Error).message || 'Lỗi khi xóa mã giảm giá', type: 'error' });
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      if (editingVoucher) {
        const updated = await updateVoucher(editingVoucher.id, {
          ...formData,
          code: formData.code.trim().toUpperCase(),
        });
        setVouchers((prev) =>
          prev.map((item) => (item.id === editingVoucher.id ? { ...item, ...updated } : item))
        );
        setMsg({ text: `Đã cập nhật mã "${formData.code}" thành công!`, type: 'success' });
      } else {
        const created = await createVoucher({
          ...formData,
          code: formData.code.trim().toUpperCase(),
        });
        setVouchers((prev) => [created, ...prev]);
        setMsg({ text: `Đã tạo mã giảm giá "${formData.code}" thành công!`, type: 'success' });
      }
      setIsModalOpen(false);
    } catch (err: unknown) {
      setMsg({ text: (err as Error).message || 'Có lỗi xảy ra', type: 'error' });
    } finally {
      setSubmitting(false);
    }
  };

  // Stats
  const totalCount = vouchers.length;
  const activeCount = vouchers.filter((v) => v.isActive).length;
  const totalUsed = vouchers.reduce((acc, cur) => acc + (cur.usedCount || 0), 0);

  // Filters
  const filteredVouchers = vouchers.filter((v) => {
    const matchesSearch =
      v.code.toLowerCase().includes(search.toLowerCase()) ||
      v.title.toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || v.discountType === typeFilter;
    const matchesStatus =
      statusFilter === 'all' ||
      (statusFilter === 'active' && v.isActive) ||
      (statusFilter === 'inactive' && !v.isActive);
    return matchesSearch && matchesType && matchesStatus;
  });

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Quản lý Mã giảm giá (Vouchers)"
        subtitle="Thiết lập các chương trình khuyến mãi, mã giảm giá % hoặc tiền mặt cho khách hàng"
        onRefresh={loadVouchers}
      />

      <div className="p-8 space-y-6 flex-1">
        {msg && (
          <div
            className={`p-3.5 rounded-xl text-xs font-semibold flex items-center justify-between gap-2 shadow-sm ${
              msg.type === 'success'
                ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30'
                : 'bg-rose-500/10 text-rose-400 border border-rose-500/30'
            }`}
          >
            <div className="flex items-center gap-2">
              {msg.type === 'success' ? (
                <CheckCircle2 className="w-4 h-4 shrink-0" />
              ) : (
                <AlertCircle className="w-4 h-4 shrink-0" />
              )}
              <span>{msg.text}</span>
            </div>
            <button
              onClick={() => setMsg(null)}
              className="text-slate-400 hover:text-white"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          </div>
        )}

        {/* Overview Stats Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-5 flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-amber-400">
              <Ticket className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs text-slate-400 font-medium">Tổng số voucher</p>
              <h3 className="text-2xl font-bold text-white mt-0.5">{totalCount}</h3>
            </div>
          </div>

          <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-5 flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400">
              <Sparkles className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs text-slate-400 font-medium">Đang hiệu lực</p>
              <h3 className="text-2xl font-bold text-white mt-0.5">{activeCount}</h3>
            </div>
          </div>

          <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-5 flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-sky-500/10 border border-sky-500/20 flex items-center justify-center text-sky-400">
              <Layers className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs text-slate-400 font-medium">Lượt đã sử dụng</p>
              <h3 className="text-2xl font-bold text-white mt-0.5">{totalUsed}</h3>
            </div>
          </div>
        </div>

        {/* Filter and Actions Bar */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 bg-slate-900/60 p-4 rounded-2xl border border-slate-800">
          <div className="flex flex-wrap items-center gap-3 w-full sm:w-auto flex-1">
            <div className="relative flex-1 sm:w-64">
              <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
              <input
                type="text"
                placeholder="Tìm mã hoặc tiêu đề..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-9 pr-3 py-1.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white placeholder:text-slate-500 focus:outline-none focus:border-amber-500 transition-colors"
              />
            </div>

            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value as 'all' | DiscountType)}
              className="px-3 py-1.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-300 focus:outline-none focus:border-amber-500"
            >
              <option value="all">Tất cả loại giảm</option>
              <option value="percentage">Phần trăm (%)</option>
              <option value="fixed_amount">Số tiền cố định (đ)</option>
            </select>

            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as 'all' | 'active' | 'inactive')}
              className="px-3 py-1.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-300 focus:outline-none focus:border-amber-500"
            >
              <option value="all">Tất cả trạng thái</option>
              <option value="active">Đang kích hoạt</option>
              <option value="inactive">Đã tạm dừng</option>
            </select>
          </div>

          <button
            onClick={openCreateModal}
            className="w-full sm:w-auto px-4 py-2 bg-amber-500 text-slate-950 rounded-xl font-bold text-xs hover:bg-amber-400 transition-colors flex items-center justify-center gap-2 cursor-pointer shadow-md shrink-0"
          >
            <Plus className="w-4 h-4" />
            Tạo mã giảm giá mới
          </button>
        </div>

        {/* Vouchers Table */}
        <div className="bg-slate-900/60 border border-slate-800 rounded-2xl overflow-hidden shadow-sm">
          {loading ? (
            <div className="p-12 text-center text-slate-400 text-sm">Đang tải danh sách mã giảm giá...</div>
          ) : filteredVouchers.length === 0 ? (
            <div className="p-12 text-center text-slate-500 text-sm">
              Không tìm thấy mã giảm giá nào phù hợp.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-slate-800 bg-slate-950/40 text-[11px] font-semibold uppercase tracking-wider text-slate-400">
                    <th className="py-3.5 px-4">Mã Voucher</th>
                    <th className="py-3.5 px-4">Chương trình / Tiêu đề</th>
                    <th className="py-3.5 px-4">Mức giảm</th>
                    <th className="py-3.5 px-4">Đơn tối thiểu</th>
                    <th className="py-3.5 px-4">Lượt dùng</th>
                    <th className="py-3.5 px-4">Thời hạn</th>
                    <th className="py-3.5 px-4 text-center">Trạng thái</th>
                    <th className="py-3.5 px-4 text-right">Thao tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60 text-xs text-slate-300">
                  {filteredVouchers.map((v) => (
                    <tr key={v.id} className="hover:bg-slate-800/30 transition-colors">
                      <td className="py-3.5 px-4">
                        <div className="flex items-center gap-2">
                          <span className="font-mono font-bold text-amber-400 bg-amber-500/10 border border-amber-500/20 px-2.5 py-1 rounded-lg">
                            {v.code}
                          </span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4 font-medium text-white max-w-xs">
                        {v.title}
                      </td>

                      <td className="py-3.5 px-4">
                        {v.discountType === 'percentage' ? (
                          <div className="flex items-center gap-1.5 text-rose-400 font-semibold">
                            <Percent className="w-3.5 h-3.5" />
                            <span>{v.discountValue}%</span>
                            {v.maxDiscount && (
                              <span className="text-[10px] text-slate-400 font-normal">
                                (Tối đa {v.maxDiscount.toLocaleString('vi-VN')}đ)
                              </span>
                            )}
                          </div>
                        ) : (
                          <div className="flex items-center gap-1.5 text-emerald-400 font-semibold">
                            <DollarSign className="w-3.5 h-3.5" />
                            <span>-{v.discountValue.toLocaleString('vi-VN')}đ</span>
                          </div>
                        )}
                      </td>

                      <td className="py-3.5 px-4 text-slate-300">
                        {v.minOrderValue > 0
                          ? `${v.minOrderValue.toLocaleString('vi-VN')}đ`
                          : '0đ (Không giới hạn)'}
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="flex items-center gap-2">
                          <div className="w-16 bg-slate-800 rounded-full h-1.5 overflow-hidden">
                            <div
                              className="bg-amber-500 h-1.5 rounded-full"
                              style={{
                                width: `${Math.min(100, ((v.usedCount || 0) / v.usageLimit) * 100)}%`,
                              }}
                            />
                          </div>
                          <span className="text-[11px] text-slate-400 font-mono">
                            {v.usedCount || 0}/{v.usageLimit}
                          </span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4 text-slate-400 text-[11px]">
                        <div className="flex items-center gap-1">
                          <Calendar className="w-3 h-3 text-slate-500 shrink-0" />
                          <span>
                            {new Date(v.startDate).toLocaleDateString('vi-VN')} -{' '}
                            {new Date(v.endDate).toLocaleDateString('vi-VN')}
                          </span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4 text-center">
                        <button
                          onClick={() => handleToggleActive(v)}
                          title={v.isActive ? 'Bấm để tạm dừng' : 'Bấm để kích hoạt'}
                          className="inline-flex items-center justify-center cursor-pointer transition-transform active:scale-95"
                        >
                          {v.isActive ? (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                              <ToggleRight className="w-4 h-4 text-emerald-400" />
                              Đang bật
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-slate-800 text-slate-400 border border-slate-700">
                              <ToggleLeft className="w-4 h-4 text-slate-500" />
                              Tạm dừng
                            </span>
                          )}
                        </button>
                      </td>

                      <td className="py-3.5 px-4 text-right">
                        <div className="flex items-center justify-end gap-1.5">
                          <button
                            onClick={() => openEditModal(v)}
                            className="p-1.5 rounded-lg text-slate-400 hover:text-amber-400 hover:bg-slate-800 transition-colors"
                            title="Sửa voucher"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleDelete(v)}
                            className="p-1.5 rounded-lg text-slate-400 hover:text-rose-400 hover:bg-slate-800 transition-colors"
                            title="Xóa voucher"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {/* Modal Add / Edit Voucher */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-lg shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
            <div className="px-6 py-4 border-b border-slate-800 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Ticket className="w-5 h-5 text-amber-400" />
                <h3 className="font-bold text-white text-base">
                  {editingVoucher ? 'Cập nhật mã giảm giá' : 'Tạo mã giảm giá mới'}
                </h3>
              </div>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-slate-400 hover:text-white p-1 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-4 overflow-y-auto flex-1">
              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1.5 uppercase tracking-wider">
                  Mã Voucher (Code) <span className="text-rose-400">*</span>
                </label>
                <input
                  type="text"
                  required
                  placeholder="VD: MENLY20, FREESHIP, TET2026"
                  value={formData.code}
                  onChange={(e) => setFormData({ ...formData, code: e.target.value.toUpperCase() })}
                  className="w-full px-3.5 py-2 bg-slate-950 border border-slate-800 rounded-xl text-sm font-mono font-bold text-amber-400 placeholder:text-slate-600 focus:outline-none focus:border-amber-500"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1.5 uppercase tracking-wider">
                  Tiêu đề / Mô tả chương trình <span className="text-rose-400">*</span>
                </label>
                <input
                  type="text"
                  required
                  placeholder="VD: Giảm ngay 50.000đ cho đơn hàng từ 300.000đ"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  className="w-full px-3.5 py-2 bg-slate-950 border border-slate-800 rounded-xl text-sm text-white placeholder:text-slate-600 focus:outline-none focus:border-amber-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1.5 uppercase tracking-wider">
                    Loại khuyến mãi
                  </label>
                  <select
                    value={formData.discountType}
                    onChange={(e) =>
                      setFormData({ ...formData, discountType: e.target.value as DiscountType })
                    }
                    className="w-full px-3.5 py-2 bg-slate-950 border border-slate-800 rounded-xl text-sm text-slate-200 focus:outline-none focus:border-amber-500"
                  >
                    <option value="percentage">Phần trăm (%)</option>
                    <option value="fixed_amount">Số tiền cố định (đ)</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1.5 uppercase tracking-wider">
                    Mức giảm {formData.discountType === 'percentage' ? '(%)' : '(VNĐ)'}{' '}
                    <span className="text-rose-400">*</span>
                  </label>
                  <input
                    type="number"
                    min={1}
                    required
                    value={formData.discountValue || ''}
                    onChange={(e) =>
                      setFormData({ ...formData, discountValue: Number(e.target.value) })
                    }
                    className="w-full px-3.5 py-2 bg-slate-950 border border-slate-800 rounded-xl text-sm text-white focus:outline-none focus:border-amber-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1.5 uppercase tracking-wider">
                    Đơn hàng tối thiểu (đ)
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={formData.minOrderValue}
                    onChange={(e) =>
                      setFormData({ ...formData, minOrderValue: Number(e.target.value) })
                    }
                    className="w-full px-3.5 py-2 bg-slate-950 border border-slate-800 rounded-xl text-sm text-white focus:outline-none focus:border-amber-500"
                  />
                </div>

                {formData.discountType === 'percentage' ? (
                  <div>
                    <label className="block text-xs font-semibold text-slate-300 mb-1.5 uppercase tracking-wider">
                      Giảm tối đa (đ)
                    </label>
                    <input
                      type="number"
                      min={0}
                      placeholder="Không giới hạn"
                      value={formData.maxDiscount ?? ''}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          maxDiscount: e.target.value ? Number(e.target.value) : null,
                        })
                      }
                      className="w-full px-3.5 py-2 bg-slate-950 border border-slate-800 rounded-xl text-sm text-white focus:outline-none focus:border-amber-500"
                    />
                  </div>
                ) : (
                  <div>
                    <label className="block text-xs font-semibold text-slate-300 mb-1.5 uppercase tracking-wider">
                      Giới hạn lượt dùng
                    </label>
                    <input
                      type="number"
                      min={1}
                      value={formData.usageLimit || 100}
                      onChange={(e) =>
                        setFormData({ ...formData, usageLimit: Number(e.target.value) })
                      }
                      className="w-full px-3.5 py-2 bg-slate-950 border border-slate-800 rounded-xl text-sm text-white focus:outline-none focus:border-amber-500"
                    />
                  </div>
                )}
              </div>

              {formData.discountType === 'percentage' && (
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1.5 uppercase tracking-wider">
                    Giới hạn lượt dùng
                  </label>
                  <input
                    type="number"
                    min={1}
                    value={formData.usageLimit || 100}
                    onChange={(e) =>
                      setFormData({ ...formData, usageLimit: Number(e.target.value) })
                    }
                    className="w-full px-3.5 py-2 bg-slate-950 border border-slate-800 rounded-xl text-sm text-white focus:outline-none focus:border-amber-500"
                  />
                </div>
              )}

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1.5 uppercase tracking-wider">
                    Ngày bắt đầu
                  </label>
                  <input
                    type="date"
                    required
                    value={formData.startDate}
                    onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
                    className="w-full px-3.5 py-2 bg-slate-950 border border-slate-800 rounded-xl text-sm text-white focus:outline-none focus:border-amber-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1.5 uppercase tracking-wider">
                    Ngày kết thúc
                  </label>
                  <input
                    type="date"
                    required
                    value={formData.endDate}
                    onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
                    className="w-full px-3.5 py-2 bg-slate-950 border border-slate-800 rounded-xl text-sm text-white focus:outline-none focus:border-amber-500"
                  />
                </div>
              </div>

              <div className="flex items-center gap-2 pt-2">
                <input
                  type="checkbox"
                  id="isActiveCheck"
                  checked={formData.isActive}
                  onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                  className="w-4 h-4 rounded border-slate-800 bg-slate-950 text-amber-500 focus:ring-0 focus:ring-offset-0"
                />
                <label htmlFor="isActiveCheck" className="text-xs font-semibold text-slate-200">
                  Kích hoạt mã voucher ngay lập tức
                </label>
              </div>

              <div className="pt-4 flex items-center justify-end gap-3 border-t border-slate-800">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 bg-slate-800 text-slate-300 rounded-xl text-xs font-medium hover:bg-slate-700 transition-colors"
                >
                  Hủy bỏ
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="px-5 py-2 bg-amber-500 text-slate-950 rounded-xl text-xs font-bold hover:bg-amber-400 transition-colors disabled:opacity-50 flex items-center gap-1.5"
                >
                  {submitting ? 'Đang lưu...' : editingVoucher ? 'Lưu thay đổi' : 'Tạo voucher'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

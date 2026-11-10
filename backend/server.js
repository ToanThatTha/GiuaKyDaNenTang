require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/quanly_nguoidung';
const JWT_SECRET = process.env.JWT_SECRET || 'doi_chuoi_bi_mat_nay';


const nguoiDungSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    matkhau: { type: String, required: true }, // lưu dạng băm bcrypt
    hoten: { type: String, required: true, trim: true },
    hinhanh: { type: String, default: '' }, // ảnh dạng data URI base64
  },
  { versionKey: false, collection: 'nguoidung' }
);


nguoiDungSchema.set('toJSON', {
  transform: (_doc, ret) => {
    delete ret.matkhau;
    return ret;
  },
});

const NguoiDung = mongoose.model('NguoiDung', nguoiDungSchema);


const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' })); // ảnh base64 nên cần tăng giới hạn

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const laHashBcrypt = (s) => typeof s === 'string' && /^\$2[aby]\$\d{2}\$/.test(s);
const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// Kiểm tra + chỉ lấy đúng 4 trường hợp lệ từ body
function docDuLieu(body, batBuocMatKhau) {
  const loi = [];
  const data = {};

  if (body.email !== undefined || batBuocMatKhau) {
    const email = String(body.email ?? '').trim().toLowerCase();
    if (!EMAIL_RE.test(email)) loi.push('Email không hợp lệ');
    data.email = email;
  }
  if (body.hoten !== undefined || batBuocMatKhau) {
    const hoten = String(body.hoten ?? '').trim();
    if (hoten.length < 2) loi.push('Họ tên phải có ít nhất 2 ký tự');
    data.hoten = hoten;
  }
  const matkhau = body.matkhau == null ? '' : String(body.matkhau);
  if (batBuocMatKhau || matkhau.length > 0) {
    if (matkhau.length < 6) loi.push('Mật khẩu phải có ít nhất 6 ký tự');
    data.matkhau = matkhau;
  }
  if (body.hinhanh !== undefined) {
    const hinhanh = String(body.hinhanh ?? '');
    if (hinhanh && !hinhanh.startsWith('data:image/') && !/^https?:\/\//.test(hinhanh)) {
      loi.push('Hình ảnh không hợp lệ');
    }
    data.hinhanh = hinhanh;
  }
  return { loi, data };
}

function xacThuc(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'Bạn chưa đăng nhập' });
  try {
    req.nguoiDung = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({ message: 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại' });
  }
}

const kiemTraId = (req, res, next) =>
  mongoose.isValidObjectId(req.params.id)
    ? next()
    : res.status(400).json({ message: 'ID không hợp lệ' });

// Bọc async để lỗi chuyển về middleware xử lý lỗi
const bat = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

// ================== ROUTES ==================
app.get('/', (_req, res) => res.json({ message: 'API quản lý người dùng đang chạy' }));

// Đăng nhập
app.post(
  '/api/auth/login',
  bat(async (req, res) => {
    const email = String(req.body.email ?? '').trim().toLowerCase();
    const matkhau = String(req.body.matkhau ?? '');
    if (!email || !matkhau) return res.status(400).json({ message: 'Vui lòng nhập email và mật khẩu' });

    const nd = await NguoiDung.findOne({ email });
    if (!nd) return res.status(401).json({ message: 'Email hoặc mật khẩu không đúng' });

    let dung = false;
    if (laHashBcrypt(nd.matkhau)) {
      dung = await bcrypt.compare(matkhau, nd.matkhau);
    } else {
      // Hỗ trợ dữ liệu nhập tay bằng Compass (mật khẩu chưa băm) -> đăng nhập xong tự băm lại
      dung = nd.matkhau === matkhau;
      if (dung) {
        nd.matkhau = await bcrypt.hash(matkhau, 10);
        await nd.save();
      }
    }
    if (!dung) return res.status(401).json({ message: 'Email hoặc mật khẩu không đúng' });

    const token = jwt.sign({ id: nd._id.toString(), email: nd.email }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: nd });
  })
);

// Thông tin người đang đăng nhập
app.get(
  '/api/auth/me',
  xacThuc,
  bat(async (req, res) => {
    const nd = await NguoiDung.findById(req.nguoiDung.id);
    if (!nd) return res.status(401).json({ message: 'Tài khoản không còn tồn tại' });
    res.json(nd);
  })
);

// Danh sách + tìm kiếm (?q=)
app.get(
  '/api/users',
  xacThuc,
  bat(async (req, res) => {
    const q = String(req.query.q ?? '').trim();
    const filter = q
      ? { $or: [{ hoten: { $regex: escapeRegex(q), $options: 'i' } }, { email: { $regex: escapeRegex(q), $options: 'i' } }] }
      : {};
    const ds = await NguoiDung.find(filter).sort({ _id: -1 });
    res.json(ds);
  })
);

// Chi tiết
app.get(
  '/api/users/:id',
  xacThuc,
  kiemTraId,
  bat(async (req, res) => {
    const nd = await NguoiDung.findById(req.params.id);
    if (!nd) return res.status(404).json({ message: 'Không tìm thấy người dùng' });
    res.json(nd);
  })
);

// Thêm
app.post(
  '/api/users',
  xacThuc,
  bat(async (req, res) => {
    const { loi, data } = docDuLieu(req.body, true);
    if (loi.length) return res.status(400).json({ message: loi.join('\n') });

    data.matkhau = await bcrypt.hash(data.matkhau, 10);
    if (data.hinhanh === undefined) data.hinhanh = '';
    const nd = await NguoiDung.create(data);
    res.status(201).json(nd);
  })
);

// Sửa (matkhau để trống = giữ nguyên)
app.put(
  '/api/users/:id',
  xacThuc,
  kiemTraId,
  bat(async (req, res) => {
    const { loi, data } = docDuLieu(req.body, false);
    if (loi.length) return res.status(400).json({ message: loi.join('\n') });

    if (data.matkhau) data.matkhau = await bcrypt.hash(data.matkhau, 10);
    const nd = await NguoiDung.findByIdAndUpdate(req.params.id, { $set: data }, { new: true, runValidators: true });
    if (!nd) return res.status(404).json({ message: 'Không tìm thấy người dùng' });
    res.json(nd);
  })
);

// Xóa
app.delete(
  '/api/users/:id',
  xacThuc,
  kiemTraId,
  bat(async (req, res) => {
    if (req.params.id === req.nguoiDung.id) {
      return res.status(400).json({ message: 'Không thể tự xóa tài khoản đang đăng nhập' });
    }
    const nd = await NguoiDung.findByIdAndDelete(req.params.id);
    if (!nd) return res.status(404).json({ message: 'Không tìm thấy người dùng' });
    res.json({ message: 'Đã xóa người dùng' });
  })
);

// Xử lý lỗi chung
app.use((err, _req, res, _next) => {
  if (err && err.code === 11000) return res.status(409).json({ message: 'Email đã tồn tại' });
  if (err && err.type === 'entity.too.large') return res.status(413).json({ message: 'Ảnh quá lớn' });
  console.error(err);
  res.status(500).json({ message: 'Lỗi máy chủ' });
});

async function taoAdminMacDinh() {
  const soLuong = await NguoiDung.countDocuments();
  if (soLuong === 0) {
    await NguoiDung.create({
      email: 'admin@gmail.com',
      matkhau: await bcrypt.hash('123456', 10),
      hoten: 'Quản trị viên',
      hinhanh: '',
    });
    console.log('Đã tạo tài khoản mặc định: admin@gmail.com / 123456');
  }
}

mongoose
  .connect(MONGO_URI)
  .then(async () => {
    console.log('Đã kết nối MongoDB:', MONGO_URI);
    await NguoiDung.syncIndexes();
    await taoAdminMacDinh();
    app.listen(PORT, '0.0.0.0', () => console.log(`API chạy tại http://localhost:${PORT}`));
  })
  .catch((e) => {
    console.error('Không kết nối được MongoDB:', e.message);
    process.exit(1);
  });

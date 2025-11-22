Nama: Moh. Jevon Attaillah
Kelas : Trpl 2D
NIM : 362458302035
Praktikum catatan geo


# Geo-Catatan – Aplikasi Geolokasi Flutter

**Geo-Catatan** merupakan aplikasi yang dikembangkan untuk memenuhi praktikum mata kuliah *Pemrograman Perangkat Bergerak*. Melalui aplikasi ini, pengguna dapat menandai suatu titik pada peta, menambahkan catatan sesuai kebutuhan, menentukan jenis lokasi, dan menyimpannya agar tetap tersimpan meskipun aplikasi ditutup.

Secara umum, aplikasi ini mengintegrasikan penggunaan GPS, peta digital, dan proses geocoding dengan cara yang sederhana sehingga mudah dipahami oleh mahasiswa.

---

## 1. Fitur Utama

Aplikasi ini telah dilengkapi beberapa fitur yang berfungsi dengan baik, antara lain:

* Menampilkan peta menggunakan flutter_map dan OpenStreetMap
* Mengambil lokasi pengguna dengan Geolocator
* Melakukan *reverse geocoding* untuk mengubah koordinat menjadi alamat
* Menambahkan marker dengan long press pada peta
* Menyimpan catatan beserta jenis lokasi (Rumah, Toko, Kantor, Sekolah)
* Menampilkan ikon marker yang berbeda berdasarkan jenis lokasi
* Menyimpan data marker menggunakan SharedPreferences
* Menghapus marker langsung dari peta

Dengan fitur tersebut, pengguna bisa membuat catatan lokasi secara cepat dan praktis.

---

## 2. Struktur Folder Project

```
lib/
│── main.dart
│── catatan_model.dart
```

File utama berisi logika aplikasi berada pada `main.dart`, sedangkan model datanya dituliskan pada `catatan_model.dart`.

---

## 3. Instalasi dan Persiapan

### A. Membuat Project Baru

```bash
flutter create catatan_geo
cd catatan_geo
```

### B. Menambahkan Dependency

Tambahkan dependensi berikut pada file `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  geolocator: ^11.0.0
  geocoding: ^3.0.0
  flutter_map: ^6.1.0
  latlong2: ^0.9.0
  shared_preferences: ^2.2.2
```

Kemudian jalankan:

```bash
flutter pub get
```

Dependensi ini digunakan untuk menampilkan peta, mengambil lokasi GPS, melakukan geocoding, dan menyimpan data secara lokal.

---

## 4. Pengaturan Permission Android

Agar aplikasi dapat menggunakan GPS dan akses internet, buka:

```
android/app/src/main/AndroidManifest.xml
```

Tambahkan izin berikut sebelum bagian `<application>`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

Tanpa izin tersebut, aplikasi tidak dapat membaca lokasi pengguna.

---

## 5. Model Data – catatan_model.dart

```dart
import 'package:latlong2/latlong.dart';

class CatatanModel {
  final LatLng position;
  final String note;
  final String address;
  final String type;

  CatatanModel({
    required this.position,
    required this.note,
    required this.address,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': position.latitude,
      'long': position.longitude,
      'note': note,
      'address': address,
      'type': type,
    };
  }

  factory CatatanModel.fromJson(Map<String, dynamic> json) {
    return CatatanModel(
      position: LatLng(json['lat'], json['long']),
      note: json['note'],
      address: json['address'],
      type: json['type'],
    );
  }
}
```

Model ini digunakan untuk menyimpan data lokasi pengguna.

---

## 6. Implementasi Utama – main.dart

Beberapa fitur utama yang diimplementasikan dalam file ini meliputi:

* Menampilkan peta OpenStreetMap
* Menambahkan marker melalui long press
* Mengubah koordinat menjadi alamat menggunakan reverse geocoding
* Form input catatan dan pemilihan jenis lokasi
* Penyimpanan dan pemuatan data melalui SharedPreferences
* Ikon marker berbeda sesuai kategori
* Fitur menghapus marker secara langsung
---

## 7. Cara Menggunakan Aplikasi

1. Buka aplikasi
2. Tekan tombol pojok kanan bawah untuk berpindah ke posisi pengguna
3. Tekan dan tahan (long press) pada titik mana pun di peta
4. Isi catatan dan pilih jenis lokasi
5. Tekan tombol “Simpan”
6. Ketuk marker untuk menampilkan opsi hapus
7. Semua data tetap tersimpan meskipun aplikasi ditutup

---

## 8. Dependensi yang Digunakan

Berikut beberapa dependensi utama:

* flutter_map – menampilkan peta
* OpenStreetMap – penyedia data peta
* geolocator – mengambil lokasi GPS
* geocoding – mengubah koordinat menjadi alamat
* shared_preferences – menyimpan data secara lokal
---
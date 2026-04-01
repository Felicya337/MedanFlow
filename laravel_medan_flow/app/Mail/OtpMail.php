<?php
namespace App\Mail;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class OtpMail extends Mailable {
    use Queueable, SerializesModels;
    public $otp;

    public function __construct($otp) { $this->otp = $otp; }

    public function build() {
        return $this->subject('Kode Verifikasi Medan Flow')
                    ->html("<h3>Kode OTP Anda adalah: <b>{$this->otp}</b></h3><p>Kode berlaku selama 10 menit.</p>");
    }
}

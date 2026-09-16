export default {
  defaultBrowser: "Google Chrome",

  rewrite: [
    {
      // Strip marketing/tracking junk from every URL
      match: () => true,
      url: (url) => {
        const tracking = [
          "fbclid", "gclid", "dclid", "gbraid", "wbraid", "msclkid",
          "yclid", "mc_eid", "mc_cid", "igshid", "ttclid", "twclid",
          "vero_id", "oly_enc_id", "oly_anon_id", "_hsenc", "_hsmi",
          "hsa_cam", "hsa_grp", "hsa_ad", "trk_contact", "trk_module",
          "ref_src", "ref_url", "spm", "scm",
        ];
        for (const key of [...url.searchParams.keys()]) {
          if (key.startsWith("utm_") || tracking.includes(key)) {
            url.searchParams.delete(key);
          }
        }
        return url;
      },
    },
  ],

  handlers: [
    {
      // Links opened from WhatsApp or iMessage go to Firefox
      match: (url, { opener }) => {
        const name = opener?.name ?? "";
        const bundleId = opener?.bundleId ?? "";
        return ["WhatsApp", "Messages"].includes(name)
          || ["net.whatsapp.WhatsApp", "com.apple.MobileSMS"].includes(bundleId);
      },
      browser: "Firefox",
    },
  ],
};

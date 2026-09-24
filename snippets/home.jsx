// Homepage for index.mdx. Styles live in /style.css under the g- prefix.
// Mintlify only keeps the body of an exported component, so every helper lives inside GrowiHome.

export const GrowiHome = () => {
  const [copied, setCopied] = useState(false);
  const [platform, setPlatform] = useState("checkout");
  const [area, setArea] = useState(0);

  const svgIcon = (name) => {
    const paths = {
      send: <><path d="M22 2 11 13" /><path d="M22 2 15 22l-4-9-9-4z" /></>,
      pointer: <path d="m4 4 7.07 16.97 2.51-7.39 7.39-2.51z" />,
      tag: <><path d="M12.6 2.6A2 2 0 0 0 11.2 2H4a2 2 0 0 0-2 2v7.2a2 2 0 0 0 .6 1.4l8.7 8.7a2.4 2.4 0 0 0 3.4 0l6.6-6.6a2.4 2.4 0 0 0 0-3.4z" /><circle cx="7.5" cy="7.5" r="1" /></>,
      refund: <><path d="M3 12a9 9 0 1 0 3-6.7L3 8" /><path d="M3 3v5h5" /></>,
      bag: <><path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" /><path d="M3 6h18M16 10a4 4 0 0 1-8 0" /></>,
      form: <><rect x="3" y="4" width="18" height="16" rx="2" /><path d="M7 9h10M7 13h6" /></>,
      bell: <><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9" /><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0" /></>,
      chart: <><path d="M3 3v18h18" /><path d="M18 17V9M13 17V5M8 17v-3" /></>,
      card: <><rect x="2" y="5" width="20" height="14" rx="2" /><path d="M2 10h20" /></>,
      code: <path d="m16 18 6-6-6-6M8 6l-6 6 6 6" />,
      key: <><circle cx="7.5" cy="15.5" r="5.5" /><path d="m21 2-9.6 9.6M15.5 7.5l3 3L22 7l-3-3" /></>,
      wrench: <path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94z" />,
      users: <><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" /></>,
      video: <><rect x="2" y="6" width="14" height="12" rx="2" /><path d="m22 8-6 4 6 4z" /></>,
      box: <><path d="M21 8 12 3 3 8v8l9 5 9-5z" /><path d="m3 8 9 5 9-5M12 13v8" /></>,
      inbox: <><path d="M22 12h-6l-2 3h-4l-2-3H2" /><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z" /></>,
      building: <><rect x="4" y="2" width="16" height="20" rx="2" /><path d="M9 22v-4h6v4M8 6h.01M12 6h.01M16 6h.01M8 10h.01M12 10h.01M16 10h.01M8 14h.01M12 14h.01M16 14h.01" /></>,
      copy: <><rect x="9" y="9" width="13" height="13" rx="2" /><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" /></>,
      check: <path d="M20 6 9 17l-5-5" />,
    };
    return (
      <svg className="g-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        {paths[name]}
      </svg>
    );
  };

  const hero = (copied, setCopied) => {
    const base = "https://api.growi.io/api/public/v1";
    const body = [
      "'{",
      '    "order_id": "ORD-12345",',
      '    "total": 9999,',
      '    "currency": "usd",',
      '    "campaign_affiliate_id": "SARAH20",',
      '    "sub_id": "instagram"',
      "  }'",
    ].join("\n");
    const copy = () => {
      navigator.clipboard?.writeText(base).then(() => {
        setCopied(true);
        setTimeout(() => setCopied(false), 1500);
      }).catch(() => {});
    };
    return (
      <section className="g-hero">
        <div className="g-hero-copy">
          <h1 className="g-h1">Build on Growi</h1>
          <p className="g-lead">Record sales, sync creator codes and pull campaign stats from one REST API.</p>
          <div className="g-btns">
            <a className="g-btn" href="/api-reference/introduction">Browse the API</a>
            <a className="g-btn g-btn-ghost" href="/authentication">Get an API key</a>
          </div>
          <button type="button" className="g-base" onClick={copy} aria-label="Copy base URL">
            <span className="g-base-label">base url</span>
            <code>{base}</code>
            {svgIcon(copied ? "check" : "copy")}
          </button>
        </div>
        <div className="g-art">
          <div className="g-art-card">
            <div className="g-art-hd"><span className="g-meth g-meth-post">POST</span>/affiliate_sales</div>
            <pre className="g-art-code">
              <span className="g-tk-p">curl</span>
              {` -X POST \\\n  ${base}/affiliate_sales \\\n  -H `}
              <span className="g-tk-s">"Authorization: Bearer $GROWI_API_KEY"</span>
              {" \\\n  -d "}
              <span className="g-tk-s">{body}</span>
            </pre>
            <div className="g-art-res">
              <span className="g-ok">201 Created</span>
              <span>id 1947457</span>
              <span>commission 500</span>
              <span>status unpaid</span>
            </div>
          </div>
        </div>
      </section>
    );
  };

  const platformPicker = (active, setActive) => {
    const platforms = [
      {
        id: "checkout",
        label: "Your own checkout",
        items: [
          ["send", "Record a sale", "POST a sale from your server when an order completes.", "/api-reference/endpoint/create-affiliate-sale"],
          ["pointer", "Track clicks and signups", "Send tracking events for the steps before a sale.", "/api-reference/endpoint/create"],
          ["tag", "Set creator codes in bulk", "Update many affiliate codes in one call.", "/api-reference/endpoint/bulk-update-campaign-affiliates"],
          ["refund", "Update or refund a sale", "PATCH a sale when an order changes.", "/api-reference/endpoint/update-affiliate-sale"],
        ],
      },
      {
        id: "shopify",
        label: "Shopify",
        items: [
          ["bag", "Add the tracking scripts", "Keep attribution working on a headless storefront.", "/essentials/shopify-headless-integration#1-add-tracking-scripts-to-your-root-file"],
          ["form", "Embed the signup form", "Let creators join your program from your site.", "/essentials/shopify-headless-integration#2-embed-the-signup-form-optional"],
          ["bell", "Get sale webhooks", "Hear about every attributed order.", "/essentials/campaign-creator-webhooks"],
          ["chart", "Pull GMV by creator", "Rank creators by the revenue they drive.", "/api-reference/endpoint/get-top-creators-by-gmv"],
        ],
      },
      {
        id: "stripe",
        label: "Stripe",
        items: [
          ["card", "Link your Stripe account", "Connect Stripe from the Growi dashboard.", "/essentials/stripe-integration"],
          ["code", "Add the growi.js script", "Capture affiliate codes when visitors land.", "/essentials/stripe-integration#2-add-our-tracking-script"],
          ["key", "Pass the code in metadata", "Send growi_affiliate_code with each payment.", "/essentials/stripe-integration#3-send-affiliate-code-to-stripe"],
          ["wrench", "Fix missing attributions", "Common Stripe setup issues and how to solve them.", "/essentials/stripe-integration#troubleshooting"],
        ],
      },
      {
        id: "tiktok",
        label: "TikTok Shop",
        items: [
          ["users", "List store creators", "Every creator selling your products.", "/api-reference/endpoint/get-tik-tok-shop-store-creators"],
          ["video", "Pull videos and lives", "Content performance for your store.", "/api-reference/endpoint/get-tik-tok-shop-store-videos"],
          ["box", "List store products", "Your catalog with sales data.", "/api-reference/endpoint/get-tik-tok-shop-store-products"],
          ["chart", "Creators per product", "Who is promoting each product.", "/api-reference/endpoint/get-tik-tok-shop-store-product-creators"],
        ],
      },
    ];
    const current = platforms.find((p) => p.id === active);
    return (
      <section className="g-sec">
        <h2 className="g-h2">Start where your sales happen</h2>
        <p className="g-sub">Pick your stack and get the shortest path to your first attributed sale.</p>
        <div className="g-pills" role="tablist" aria-label="Platform">
          {platforms.map((p) => (
            <button
              key={p.id}
              type="button"
              role="tab"
              aria-selected={p.id === active}
              className="g-pill"
              onClick={() => setActive(p.id)}
            >
              {p.label}
            </button>
          ))}
        </div>
        <div className="g-qs" role="tabpanel">
          {current.items.map(([icon, title, text, href]) => (
            <a key={title} className="g-q" href={href}>
              <span className="g-q-icon">{svgIcon(icon)}</span>
              <span>
                <span className="g-q-title">{title}</span>
                <span className="g-q-text">{text}</span>
              </span>
            </a>
          ))}
        </div>
      </section>
    );
  };

  const apiExplorer = (active, setActive) => {
    const ep = (slug) => `/api-reference/endpoint/${slug}`;
    const areas = [
      { icon: "send", name: "Conversions", text: "Record, list and update sales", count: 3, rows: [
        ["post", "Create affiliate sale", "/affiliate_sales", ep("create-affiliate-sale")],
        ["get", "List affiliate sales", "/affiliate_sales", ep("list-affiliate-sales")],
        ["patch", "Update affiliate sale", "/affiliate_sales/{id}", ep("update-affiliate-sale")],
      ] },
      { icon: "tag", name: "Campaign affiliates", text: "Creator enrollments and codes", count: 3, rows: [
        ["get", "List campaign affiliates", "/campaign_affiliates", ep("list-campaign-affiliates")],
        ["patch", "Update campaign affiliate", "/campaign_affiliates/{id}", ep("update-campaign-affiliate")],
        ["patch", "Bulk update campaign affiliates", "/campaign_affiliates/bulk", ep("bulk-update-campaign-affiliates")],
      ] },
      { icon: "inbox", name: "Applications", text: "Submit creators into a campaign", count: 1, rows: [
        ["post", "Create campaign application", "/campaign_applications", ep("create-campaign-application")],
      ] },
      { icon: "building", name: "Organization", text: "Brands and campaigns", count: 2, rows: [
        ["get", "List brands", "/organizations/brands", ep("get-brands")],
        ["get", "List campaigns", "/organizations/campaigns", ep("get-campaigns")],
      ] },
      { icon: "chart", name: "Stats", text: "Creators, content, GMV and payouts", count: 17, rows: [
        ["get", "Get snapshots", "/stats/snapshots", ep("get-snapshots")],
        ["get", "Get top creators by GMV", "/stats/top_creators_by_gmv", ep("get-top-creators-by-gmv")],
        ["get", "Get top posts by views", "/stats/top_posts_by_views", ep("get-top-posts-by-views")],
        ["get", "List transactions", "/stats/transactions", ep("get-transactions")],
        ["post", "Refresh data", "/stats/refresh_data", ep("refresh-data")],
      ] },
      { icon: "video", name: "TikTok Shop", text: "Store creators, videos, LIVE streams, products", count: 7, rows: [
        ["get", "List TikTok Shop creators", "/tik_tok_shop/creators", ep("get-tik-tok-shop-store-creators")],
        ["get", "List TikTok Shop videos", "/tik_tok_shop/videos", ep("get-tik-tok-shop-store-videos")],
        ["get", "List TikTok Shop LIVE streams", "/tik_tok_shop/lives", ep("get-tik-tok-shop-store-lives")],
        ["get", "List TikTok Shop products", "/tik_tok_shop/products", ep("get-tik-tok-shop-store-products")],
        ["get", "Get top TikTok Shop products by GMV", "/stats/tik_tok_shop_products", ep("get-tik-tok-shop-products")],
      ] },
      { icon: "pointer", name: "Tracking events", text: "Clicks, signups and custom events", count: 1, rows: [
        ["post", "Create tracking event", "/tracking_events", ep("create")],
      ] },
      { icon: "bell", name: "Webhooks", text: "Push events to your server", count: 5, rows: [
        ["event", "Creator activated", "campaign_affiliate.activated", "/webhooks/examples"],
        ["event", "Creator removed", "campaign_affiliate.removed", "/webhooks/examples"],
        ["event", "Creator left", "campaign_affiliate.left", "/webhooks/examples"],
        ["event", "Code updated", "campaign_affiliate.code_updated", "/webhooks/examples"],
        ["event", "Sale attributed", "affiliate_sale.created", "/webhooks/examples"],
      ] },
    ];
    const area = areas[active];
    return (
      <section className="g-sec">
        <h2 className="g-h2">The whole API on one screen</h2>
        <p className="g-sub">34 endpoints and 5 webhook events, grouped by the job they do.</p>
        <div className="g-x">
          <div className="g-x-list" role="tablist" aria-label="API area">
            {areas.map((a, i) => (
              <button
                key={a.name}
                type="button"
                role="tab"
                aria-selected={i === active}
                className="g-x-item"
                onClick={() => setActive(i)}
              >
                {svgIcon(a.icon)}
                <span>
                  <span className="g-x-name">{a.name}</span>
                  <span className="g-x-text">{a.text}</span>
                </span>
                <span className="g-x-count">{a.count}</span>
              </button>
            ))}
          </div>
          <div className="g-x-panel" role="tabpanel">
            <p className="g-x-title">{area.name}</p>
            <p className="g-x-desc">
              {area.text}
              {area.count > area.rows.length ? `. Showing ${area.rows.length} of ${area.count}.` : "."}
            </p>
            {area.rows.map(([method, title, path, href]) => (
              <a key={title} className="g-ep" href={href}>
                <span className={`g-meth g-meth-${method}`}>{method.toUpperCase()}</span>
                <span className="g-ep-body">
                  <span className="g-ep-title">{title}</span>
                  <span className="g-ep-path">{path}</span>
                </span>
              </a>
            ))}
            <a className="g-x-more" href={area.name === "Webhooks" ? "/essentials/campaign-creator-webhooks" : area.rows[0][3]}>
              {area.name === "Webhooks" ? "Read the webhooks guide" : `See all ${area.count} in the reference`}
            </a>
          </div>
        </div>
      </section>
    );
  };

  const guideCards = () => {
    const cards = [
      { icon: "card", tone: "blue", title: "Stripe", text: "Link Stripe, add growi.js, pass the code in payment metadata.", tags: ["Payments"], href: "/essentials/stripe-integration" },
      { icon: "bag", tone: "ink", title: "Shopify headless", text: "Carry the affiliate code from landing page through checkout.", tags: ["Storefront"], href: "/essentials/shopify-headless-integration" },
      { icon: "bell", tone: "soft", title: "Webhooks", text: "Get notified when creators join, leave, change codes or drive a sale.", tags: ["Events"], href: "/essentials/campaign-creator-webhooks" },
    ];
    return (
      <section className="g-sec">
        <h2 className="g-h2">Integration guides</h2>
        <p className="g-sub">Step-by-step setups for the platforms brands use most.</p>
        <div className="g-cards">
          {cards.map((c) => (
            <a key={c.title} className="g-card" href={c.href}>
              <span className={`g-card-art g-tone-${c.tone}`}>{svgIcon(c.icon)}</span>
              <span className="g-card-body">
                <span className="g-card-title">{c.title}</span>
                <span className="g-card-text">{c.text}</span>
                <span>{c.tags.map((t) => <span key={t} className="g-tag">{t}</span>)}</span>
              </span>
            </a>
          ))}
        </div>
      </section>
    );
  };

  return (
    <div className="g-home">
      {hero(copied, setCopied)}
      {platformPicker(platform, setPlatform)}
      {apiExplorer(area, setArea)}
      {guideCards()}
      <footer className="g-foot">
        <img className="g-foot-logo g-foot-logo-light" src="/logo/light.svg" alt="Growi" />
        <img className="g-foot-logo g-foot-logo-dark" src="/logo/dark.svg" alt="Growi" />
        <span>API docs for brands and developers</span>
        <nav aria-label="Footer">
          <a href="https://growi.io">Website</a>
          <a href="mailto:info@growi.io">Support</a>
          <a href="/api-reference/introduction">API reference</a>
        </nav>
      </footer>
    </div>
  );
};

document.addEventListener('DOMContentLoaded',()=>{
  const navToggle=document.getElementById('navToggle');
  const mainNav=document.getElementById('mainNav');
  navToggle?.addEventListener('click',()=>{
    mainNav.classList.toggle('open');
  });

  // Smooth scroll for internal links
  document.querySelectorAll('a[href^="#"]').forEach(a=>{
    a.addEventListener('click',e=>{
      const href=a.getAttribute('href');
      if(href && href.length>1){
        const el=document.querySelector(href);
        if(el){
          e.preventDefault();
          el.scrollIntoView({behavior:'smooth',block:'start'});
          mainNav.classList.remove('open');
        }
      }
    });
  });

  // Footer year
  const yearEl=document.getElementById('year');
  if(yearEl){yearEl.textContent=new Date().getFullYear();}

  // Contact form (demo)
  const btn=document.getElementById('sendBtn');
  btn?.addEventListener('click',()=>{
    alert('Teşekkürler! En kısa sürede sizinle iletişime geçeceğiz.\n(Entegrasyon: e-posta/WhatsApp/CRM)');
  });

  // Project image click-to-zoom (subtle)
  document.querySelectorAll('.project img').forEach(img=>{
    img.addEventListener('click',()=>{
      img.classList.add('clicked');
      // remove after short duration so it doesn't stay scaled
      setTimeout(()=>img.classList.remove('clicked'), 450);
    });
  });
});

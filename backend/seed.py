"""
Run: python seed.py
Creates initial categories, brands, sample products, and an admin user.
"""
import asyncio
import uuid
from decimal import Decimal
from app.database import AsyncSessionLocal, engine, Base
from app.models import User, Profile, Category, Brand, Product
from app.services.auth_service import hash_password


CATEGORIES = [
    {"name": "Tecnología", "slug": "tecnologia"},
    {"name": "Deporte", "slug": "deporte"},
    {"name": "Electrohogar", "slug": "electrohogar"},
    {"name": "Moda", "slug": "moda"},
]

BRANDS = [
    {"name": "Apple", "slug": "apple", "category_slug": "tecnologia"},
    {"name": "Sony", "slug": "sony", "category_slug": "tecnologia"},
    {"name": "Dell", "slug": "dell", "category_slug": "tecnologia"},
    {"name": "Nike", "slug": "nike", "category_slug": "deporte"},
    {"name": "Adidas", "slug": "adidas", "category_slug": "deporte"},
    {"name": "Puma", "slug": "puma", "category_slug": "deporte"},
    {"name": "Samsung", "slug": "samsung", "category_slug": "electrohogar"},
    {"name": "LG", "slug": "lg", "category_slug": "electrohogar"},
    {"name": "Bosch", "slug": "bosch", "category_slug": "electrohogar"},
]

PRODUCTS = [
    {"name": "iPhone 15 Pro", "description": "El smartphone más avanzado de Apple con chip A17 Pro.", "price": Decimal("5999.00"), "stock": 50, "rating_avg": 4.8, "rating_count": 320, "image_url": "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-15-pro-finish-select-202309-6-7inch-naturaltitanium?wid=400&hei=400&fmt=png-alpha", "category_slug": "tecnologia", "brand_slug": "apple"},
    {"name": "MacBook Air M2", "description": "Laptop ultradelgada con chip M2, 8GB RAM y 256GB SSD.", "price": Decimal("6299.00"), "stock": 30, "rating_avg": 4.9, "rating_count": 215, "image_url": "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/macbook-air-midnight-select-20220606?wid=400&hei=400&fmt=jpeg", "category_slug": "tecnologia", "brand_slug": "apple"},
    {"name": "AirPods Pro 2", "description": "Audífonos inalámbricos con cancelación de ruido activa.", "price": Decimal("1099.00"), "stock": 80, "rating_avg": 4.7, "rating_count": 540, "image_url": "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/MQD83?wid=400&hei=400&fmt=jpeg", "category_slug": "tecnologia", "brand_slug": "apple"},
    {"name": "Sony WH-1000XM5", "description": "Audífonos over-ear con la mejor cancelación de ruido del mercado.", "price": Decimal("1299.00"), "stock": 45, "rating_avg": 4.8, "rating_count": 890, "image_url": "https://www.bhphotovideo.com/images/images2500x2500/sony_wh1000xm5_b_wh_1000xm5_wireless_noise_canceling_overhead_1668335.jpg", "category_slug": "tecnologia", "brand_slug": "sony"},
    {"name": "Sony PlayStation 5", "description": "Consola de videojuegos de última generación con SSD ultrarrápido.", "price": Decimal("2599.00"), "stock": 20, "rating_avg": 4.9, "rating_count": 1200, "image_url": "https://gmedia.playstation.com/is/image/SIEPDC/ps5-product-thumbnail-01-en-14sep21?$800px$", "category_slug": "tecnologia", "brand_slug": "sony"},
    {"name": "Dell XPS 15", "description": "Laptop premium con pantalla OLED 4K y Intel Core i9.", "price": Decimal("7499.00"), "stock": 15, "rating_avg": 4.6, "rating_count": 178, "image_url": "https://i.dell.com/is/image/DellContent/content/dam/ss2/product-images/dell-client-products/notebooks/xps-notebooks/xps-15-9530/media-gallery/black/notebook-xps-15-9530-t-black-gallery-1.psd?fmt=pjpg&pscan=auto&scl=1&hei=402&wid=402&qlt=100,1&resMode=sharp2&size=402,402&chrss=full", "category_slug": "tecnologia", "brand_slug": "dell"},
    {"name": "Nike Air Max 270", "description": "Zapatillas deportivas con amortiguación Air Max visible.", "price": Decimal("499.00"), "stock": 120, "rating_avg": 4.5, "rating_count": 670, "image_url": "https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/skwgyqrbfzhu6uyeh0gg/air-max-270-mens-shoes-KkLcGR.png", "category_slug": "deporte", "brand_slug": "nike"},
    {"name": "Nike Pro Dri-FIT", "description": "Camiseta deportiva con tecnología Dri-FIT para máximo rendimiento.", "price": Decimal("149.00"), "stock": 200, "rating_avg": 4.4, "rating_count": 430, "image_url": "https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/4e32cbb7-2b0f-4869-954c-1148a4614dd3/pro-dri-fit-tight-short-sleeve-top-QhPSMH.png", "category_slug": "deporte", "brand_slug": "nike"},
    {"name": "Adidas Ultraboost 23", "description": "Zapatillas de running con tecnología Boost para máxima energía.", "price": Decimal("599.00"), "stock": 90, "rating_avg": 4.7, "rating_count": 520, "image_url": "https://assets.adidas.com/images/h_840,f_auto,q_auto,fl_lossy,c_fill,g_auto/cd5428d0b2334e8ea9a7afc0015a7c86_9366/Ultraboost_Light_Running_Shoes_White_GZ5159_01_standard.jpg", "category_slug": "deporte", "brand_slug": "adidas"},
    {"name": "Puma RS-X", "description": "Zapatillas retro con diseño chunky y suela gruesa.", "price": Decimal("329.00"), "stock": 75, "rating_avg": 4.3, "rating_count": 280, "image_url": "https://images.puma.com/image/upload/f_auto,q_auto,b_rgb:fafafa,w_600,h_600/global/374740/01/sv01/fnd/PNA/fmt/png/RS-X-Toys-Sneakers", "category_slug": "deporte", "brand_slug": "puma"},
    {"name": "Samsung Galaxy S24 Ultra", "description": "Smartphone flagship con S Pen integrado y cámara de 200MP.", "price": Decimal("5499.00"), "stock": 40, "rating_avg": 4.8, "rating_count": 760, "image_url": "https://images.samsung.com/is/image/samsung/p6pim/pe/2401/gallery/pe-galaxy-s24-ultra-s928-sm-s928bzkgpeo-thumb-539573183?$650_519_PNG$", "category_slug": "electrohogar", "brand_slug": "samsung"},
    {"name": "Samsung Neo QLED 4K 55\"", "description": "Smart TV Neo QLED con tecnología Quantum Matrix y 4K.", "price": Decimal("3999.00"), "stock": 25, "rating_avg": 4.7, "rating_count": 345, "image_url": "https://images.samsung.com/is/image/samsung/p6pim/pe/qn55qn85caexzl/gallery/pe-qled-tv-qn55qn85caexzl-535293773?$650_519_PNG$", "category_slug": "electrohogar", "brand_slug": "samsung"},
    {"name": "LG OLED C3 65\"", "description": "TV OLED evo con pixel self-illuminating para negros perfectos.", "price": Decimal("6799.00"), "stock": 12, "rating_avg": 4.9, "rating_count": 423, "image_url": "https://www.lg.com/pe/images/tvs/md08002977/gallery/DZ-01.jpg", "category_slug": "electrohogar", "brand_slug": "lg"},
    {"name": "Bosch Serie 6 Lavadora", "description": "Lavadora 9kg con tecnología ActiveWater Plus y A+++.", "price": Decimal("2799.00"), "stock": 18, "rating_avg": 4.6, "rating_count": 192, "image_url": "https://media3.bosch-home.com/Images/9999999999/9999999999_def.jpg", "category_slug": "electrohogar", "brand_slug": "bosch"},
    {"name": "Apple Watch Series 9", "description": "Smartwatch con chip S9 y pantalla Always-On Retina.", "price": Decimal("1599.00"), "stock": 60, "rating_avg": 4.7, "rating_count": 890, "image_url": "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/MQDY3ref_AV3_GEO_PE?wid=400&hei=400&fmt=jpeg", "category_slug": "tecnologia", "brand_slug": "apple"},
]


async def main():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as db:
        # Categories
        cat_map = {}
        for c in CATEGORIES:
            from sqlalchemy import select
            existing = (await db.execute(select(Category).where(Category.slug == c["slug"]))).scalar_one_or_none()
            if not existing:
                cat = Category(name=c["name"], slug=c["slug"])
                db.add(cat)
                await db.flush()
                cat_map[c["slug"]] = cat.id
            else:
                cat_map[c["slug"]] = existing.id

        # Brands
        brand_map = {}
        for b in BRANDS:
            from sqlalchemy import select
            existing = (await db.execute(select(Brand).where(Brand.slug == b["slug"]))).scalar_one_or_none()
            if not existing:
                brand = Brand(name=b["name"], slug=b["slug"], category_id=cat_map.get(b["category_slug"]))
                db.add(brand)
                await db.flush()
                brand_map[b["slug"]] = brand.id
            else:
                brand_map[b["slug"]] = existing.id

        # Products
        for p in PRODUCTS:
            from sqlalchemy import select
            existing = (await db.execute(select(Product).where(Product.name == p["name"]))).scalar_one_or_none()
            if not existing:
                product = Product(
                    id=str(uuid.uuid4()),
                    name=p["name"],
                    description=p["description"],
                    price=p["price"],
                    stock=p["stock"],
                    rating_avg=p["rating_avg"],
                    rating_count=p["rating_count"],
                    image_url=p["image_url"],
                    category_id=cat_map.get(p["category_slug"]),
                    brand_id=brand_map.get(p["brand_slug"]),
                )
                db.add(product)

        # Admin user
        from sqlalchemy import select
        admin_email = "admin@goldenbears.com"
        existing_admin = (await db.execute(select(User).where(User.email == admin_email))).scalar_one_or_none()
        if not existing_admin:
            admin = User(
                id=str(uuid.uuid4()),
                email=admin_email,
                hashed_password=hash_password("Admin1234!"),
                role="admin",
            )
            db.add(admin)
            await db.flush()
            db.add(Profile(id=str(uuid.uuid4()), user_id=admin.id, full_name="Admin Golden Bears"))
            print(f"Admin created: {admin_email} / Admin1234!")

        await db.commit()
        print("Seed completed successfully!")


if __name__ == "__main__":
    asyncio.run(main())

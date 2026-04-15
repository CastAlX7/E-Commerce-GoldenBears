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
    {"id": "c9c10297-463b-4f6a-a144-9b523dadd969", "name": "iPhone 15 Pro", "description": "El smartphone más avanzado de Apple con chip A17 Pro.", "price": Decimal("5999.00"), "stock": 50, "rating_avg": 4.8, "rating_count": 320, "image_url": "/static/images/c9c10297-463b-4f6a-a144-9b523dadd969.png", "category_slug": "tecnologia", "brand_slug": "apple"},
    {"id": "44012204-0874-44de-bd3e-c9e30805c51a", "name": "MacBook Air M2", "description": "Laptop ultradelgada con chip M2, 8GB RAM y 256GB SSD.", "price": Decimal("6299.00"), "stock": 30, "rating_avg": 4.9, "rating_count": 215, "image_url": "/static/images/44012204-0874-44de-bd3e-c9e30805c51a.jpg", "category_slug": "tecnologia", "brand_slug": "apple"},
    {"id": "e3e9a207-0954-447e-be3b-a90b21bd2b02", "name": "AirPods Pro 2", "description": "Audífonos inalámbricos con cancelación de ruido activa.", "price": Decimal("1099.00"), "stock": 80, "rating_avg": 4.7, "rating_count": 540, "image_url": "/static/images/e3e9a207-0954-447e-be3b-a90b21bd2b02.png", "category_slug": "tecnologia", "brand_slug": "apple"},
    {"id": "2193b55b-49f0-4647-8a71-38fb3e15f27b", "name": "Sony WH-1000XM5", "description": "Audífonos over-ear con la mejor cancelación de ruido del mercado.", "price": Decimal("1299.00"), "stock": 45, "rating_avg": 4.8, "rating_count": 890, "image_url": "/static/images/2193b55b-49f0-4647-8a71-38fb3e15f27b.jpg", "category_slug": "tecnologia", "brand_slug": "sony"},
    {"id": "28c1b8aa-97a9-443d-a03e-4de662acb5cd", "name": "Sony PlayStation 5", "description": "Consola de videojuegos de última generación con SSD ultrarrápido.", "price": Decimal("2599.00"), "stock": 20, "rating_avg": 4.9, "rating_count": 1200, "image_url": "/static/images/28c1b8aa-97a9-443d-a03e-4de662acb5cd.jpg", "category_slug": "tecnologia", "brand_slug": "sony"},
    {"id": "c81d3a87-3190-45f1-b1c0-fb3c76b97c61", "name": "Dell XPS 15", "description": "Laptop premium con pantalla OLED 4K y Intel Core i9.", "price": Decimal("7499.00"), "stock": 15, "rating_avg": 4.6, "rating_count": 178, "image_url": "/static/images/c81d3a87-3190-45f1-b1c0-fb3c76b97c61.png", "category_slug": "tecnologia", "brand_slug": "dell"},
    {"id": "737d92dd-62fd-4f51-971e-6f46e97b3f45", "name": "Nike Air Max 270", "description": "Zapatillas deportivas con amortiguación Air Max visible.", "price": Decimal("499.00"), "stock": 120, "rating_avg": 4.5, "rating_count": 670, "image_url": "/static/images/737d92dd-62fd-4f51-971e-6f46e97b3f45.png", "category_slug": "deporte", "brand_slug": "nike"},
    {"id": "d8555879-94a9-45ce-a94f-1c2f635273a3", "name": "Nike Pro Dri-FIT", "description": "Camiseta deportiva con tecnología Dri-FIT para máximo rendimiento.", "price": Decimal("149.00"), "stock": 200, "rating_avg": 4.4, "rating_count": 430, "image_url": "/static/images/d8555879-94a9-45ce-a94f-1c2f635273a3.jpg", "category_slug": "deporte", "brand_slug": "nike"},
    {"id": "7dedb9da-2676-40bb-a035-49e9324dc046", "name": "Adidas Ultraboost 23", "description": "Zapatillas de running con tecnología Boost para máxima energía.", "price": Decimal("599.00"), "stock": 90, "rating_avg": 4.7, "rating_count": 520, "image_url": "/static/images/7dedb9da-2676-40bb-a035-49e9324dc046.png", "category_slug": "deporte", "brand_slug": "adidas"},
    {"id": "44c2fd70-5a5a-4888-a2b1-7b08fb1edeb5", "name": "Puma RS-X", "description": "Zapatillas retro con diseño chunky y suela gruesa.", "price": Decimal("329.00"), "stock": 75, "rating_avg": 4.3, "rating_count": 280, "image_url": "/static/images/44c2fd70-5a5a-4888-a2b1-7b08fb1edeb5.jpg", "category_slug": "deporte", "brand_slug": "puma"},
    {"id": "135ee79a-92ae-463b-ac31-ded6685b56ed", "name": "Samsung Galaxy S24 Ultra", "description": "Smartphone flagship con S Pen integrado y cámara de 200MP.", "price": Decimal("5499.00"), "stock": 40, "rating_avg": 4.8, "rating_count": 760, "image_url": "/static/images/135ee79a-92ae-463b-ac31-ded6685b56ed.jpg", "category_slug": "electrohogar", "brand_slug": "samsung"},
    {"id": "9773d65f-3e71-434d-9549-2b045cba4d7f", "name": "Samsung Neo QLED 4K 55\"", "description": "Smart TV Neo QLED con tecnología Quantum Matrix y 4K.", "price": Decimal("3999.00"), "stock": 25, "rating_avg": 4.7, "rating_count": 345, "image_url": "/static/images/9773d65f-3e71-434d-9549-2b045cba4d7f.png", "category_slug": "electrohogar", "brand_slug": "samsung"},
    {"id": "405d976c-7d8c-4d78-bd3f-d3e2977b32c5", "name": "LG OLED C3 65\"", "description": "TV OLED evo con pixel self-illuminating para negros perfectos.", "price": Decimal("6799.00"), "stock": 12, "rating_avg": 4.9, "rating_count": 423, "image_url": "/static/images/405d976c-7d8c-4d78-bd3f-d3e2977b32c5.jpg", "category_slug": "electrohogar", "brand_slug": "lg"},
    {"id": "8c1842f0-72d1-41ad-bebe-b5076cd96bc6", "name": "Bosch Serie 6 Lavadora", "description": "Lavadora 9kg con tecnología ActiveWater Plus y A+++.", "price": Decimal("2799.00"), "stock": 18, "rating_avg": 4.6, "rating_count": 192, "image_url": "/static/images/8c1842f0-72d1-41ad-bebe-b5076cd96bc6.png", "category_slug": "electrohogar", "brand_slug": "bosch"},
    {"id": "719ebe33-2191-40ff-86ee-ecce1f857e9e", "name": "Apple Watch Series 9", "description": "Smartwatch con chip S9 y pantalla Always-On Retina.", "price": Decimal("1599.00"), "stock": 60, "rating_avg": 4.7, "rating_count": 890, "image_url": "/static/images/719ebe33-2191-40ff-86ee-ecce1f857e9e.jpg", "category_slug": "tecnologia", "brand_slug": "apple"},
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
            existing = (await db.execute(select(Product).where(Product.id == p["id"]))).scalar_one_or_none()
            if not existing:
                product = Product(
                    id=p["id"],
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

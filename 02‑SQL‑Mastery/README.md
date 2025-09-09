# GRIT: SQL Mastery (7 Days)

==> About Growth through Rigorous Iterative Training

Welcome to SQL Mastery! This 7-day intensive course will take you from SQL beginner to confident database querier. Each day builds practical skills through hands-on exercises with real data.

**Instructor**: Muhammad Ibrahim Qasmi
<br>
**LinkedIn**: [Connect with me](https://www.linkedin.com/in/ibrahimqasmi313/)

## 📚 Course Structure

| Day | Notebook | Topic | What You'll Learn |
|-----|----------|-------|-------------------|
| 1 | `01_sql_basics.ipynb` | SQL Fundamentals | Database concepts, SELECT basics, WHERE filtering |
| 2 | `02_data_types_operators.ipynb` | Data Types & Operators | SQL data types, comparison/logical operators, pattern matching |
| 3 | `03_aggregation_grouping.ipynb` | Aggregation & Grouping | COUNT, SUM, AVG, GROUP BY, HAVING clauses |
| 4 | `04_joins_relationships.ipynb` | JOINs & Relationships | INNER/LEFT/RIGHT joins, table relationships, multiple joins |
| 5 | `05_subqueries_ctes.ipynb` | Advanced Queries | Subqueries, Common Table Expressions (CTEs), complex filtering |
| 6 | `06_data_manipulation.ipynb` | Data Modification | INSERT, UPDATE, DELETE, CREATE TABLE, data integrity |
| 7 | `07_sql_project.ipynb` | SQL Project | Real-world e-commerce analytics project, performance optimization |

## 🛠️ SQL Learning Format

### **Primary Format: Jupyter Notebooks**
- Interactive learning with immediate feedback
- SQL magic commands (`%sql` and `%%sql`)
- Visual query results and explanations
- Integrated exercises and solutions

### **Supporting Files:**
- `.sql` files: Pure SQL scripts for reference
- `.db` files: SQLite databases for practice
- `.csv` files: Sample data files

## 🎯 Learning Approach

- **Query-First**: Learn by writing and running actual SQL queries
- **Data-Centric**: Work with realistic datasets (e-commerce, sales, etc.)
- **Progressive Difficulty**: Start simple, build to complex real-world scenarios
- **Practical Focus**: Every concept includes hands-on exercises
- **Performance Minded**: Learn efficient query patterns from Day 1

## 📖 How to Use These Materials

1. **Install Dependencies**:
   ```bash
   pip install jupyter ipython-sql sqlalchemy pandas matplotlib
   ```

2. **Start SQLite**:
   ```python
   %load_ext sql
   %sql sqlite:///sample_data.db
   ```

3. **Follow the Daily Rhythm**:
   - Read theory and examples (15-20 min)
   - Code along with examples (20-30 min)
   - Complete exercises (30-45 min)
   - Debug and optimize queries (15-20 min)

## 📊 Sample Database

We use SQLite with a realistic e-commerce dataset including:
- `customers` table: Customer information
- `orders` table: Order details
- `products` table: Product catalog
- `order_items` table: Order line items

## 🛠️ Prerequisites

- Basic computer literacy
- Understanding of data concepts (from Python Fundamentals)
- SQLite installed (comes with Python)
- No prior SQL experience needed!

## 📞 Support & Resources

### **Getting Help:**
- Review the hints in each notebook
- Check the `.sql` reference files
- Use SQLite's error messages as guides
- Break complex queries into smaller steps

### **Additional Resources:**
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [SQLZoo Practice](https://sqlzoo.net/) - Interactive SQL learning
- [Mode Analytics SQL Tutorial](https://mode.com/sql-tutorial/)

### **Debugging Tips:**
- Use `SELECT *` to explore table structure
- Check column names and data types
- Verify JOIN conditions carefully
- Use `LIMIT` when testing queries

---

**Ready to master SQL? Open `01_sql_basics.ipynb` and let's query! 🚀**

## 📈 Daily Learning Goals

- **Day 1-2**: Read and filter data confidently
- **Day 3-4**: Analyze data with aggregations and relationships
- **Day 5-6**: Write complex, efficient queries
- **Day 7**: Apply SQL to real business problems

Remember: SQL is like a superpower for data - start simple, practice daily, and you'll be amazed at what you can accomplish!

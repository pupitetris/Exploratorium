PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Table: attr_class
DROP TABLE IF EXISTS attr_class;

CREATE TABLE attr_class (
	attr_class_id INTEGER
		PRIMARY KEY AUTOINCREMENT,
	code TEXT
		UNIQUE NOT NULL
		COLLATE NOCASE,
	ord INTEGER
		UNIQUE NOT NULL,
	CHECK (code <> ''))
STRICT;


-- Table: attr_class_desc
DROP TABLE IF EXISTS attr_class_desc;

CREATE TABLE attr_class_desc (
	attr_class_id INTEGER
		REFERENCES attr_class (attr_class_id)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT
		DEFERRABLE INITIALLY DEFERRED,
	lang_code TEXT
		REFERENCES lang (lang_code)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT
		DEFERRABLE INITIALLY DEFERRED,
	title TEXT
		NOT NULL
		COLLATE NOCASE,
	PRIMARY KEY (attr_class_id, lang_code),
	CHECK (title <> ''))
STRICT;


-- Table: attr_context_class
DROP TABLE IF EXISTS attr_context_class;

CREATE TABLE attr_context_class (
	attribute_id INTEGER
		REFERENCES attribute (attribute_id)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT
		DEFERRABLE INITIALLY DEFERRED,
	context_class_id INTEGER
		REFERENCES context_class (context_class_id)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT
		DEFERRABLE INITIALLY DEFERRED,
	attr_class_id INTEGER
		REFERENCES attr_class (attr_class_id)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT
		DEFERRABLE INITIALLY DEFERRED,
	reference TEXT,
	PRIMARY KEY (attribute_id, context_class_id),
	CHECK (reference <> ''))
STRICT;


-- Table: attribute
DROP TABLE IF EXISTS attribute;

CREATE TABLE attribute (
	attribute_id INTEGER
		PRIMARY KEY AUTOINCREMENT,
	formula TEXT,
	CHECK (formula <> ''))
STRICT;


-- Table: attribute_context
DROP TABLE IF EXISTS attribute_context;

CREATE TABLE attribute_context (
	attribute_id INTEGER
		REFERENCES attribute (attribute_id)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT
		DEFERRABLE INITIALLY DEFERRED,
	context_id INTEGER
		REFERENCES context (context_id)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT
		DEFERRABLE INITIALLY DEFERRED,
	PRIMARY KEY (attribute_id, context_id))
STRICT;


-- Table: attribute_desc
DROP TABLE IF EXISTS attribute_desc;

CREATE TABLE attribute_desc (
	attribute_id INTEGER,
	context_class_id INTEGER,
	lang_code TEXT
		REFERENCES lang (lang_code)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT
		DEFERRABLE INITIALLY DEFERRED,
	label TEXT
		NOT NULL
		COLLATE NOCASE,
	title TEXT
		DEFAULT NULL,
	explanation TEXT
		DEFAULT NULL,
	obs TEXT,
	PRIMARY KEY (attribute_id, context_class_id, lang_code),
	FOREIGN KEY (attribute_id, context_class_id)
		REFERENCES attr_context_class (attribute_id, context_class_id)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT
		DEFERRABLE INITIALLY DEFERRED,
	UNIQUE (context_class_id, lang_code, label),
	CHECK (label <> '' and title <> '' AND explanation <> '' and obs <> ''))
STRICT;


-- Table: context
DROP TABLE IF EXISTS context;

CREATE TABLE context (
	context_id INTEGER
		PRIMARY KEY AUTOINCREMENT,
	context_class_id INTEGER
		REFERENCES context_class (context_class_id)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT
		DEFERRABLE INITIALLY DEFERRED,
	code TEXT
		NOT NULL
		UNIQUE COLLATE NOCASE,
	CHECK (code <> ''))
STRICT;


-- Table: context_class
DROP TABLE IF EXISTS context_class;

CREATE TABLE context_class (
	context_class_id INTEGER
		PRIMARY KEY AUTOINCREMENT,
	code TEXT
		UNIQUE COLLATE NOCASE
		NOT NULL,
	CHECK (code <> ''))
STRICT;


-- Table: lang
DROP TABLE IF EXISTS lang;

CREATE TABLE lang (
	lang_code TEXT
		PRIMARY KEY
		COLLATE NOCASE,
	lang_label TEXT
		UNIQUE COLLATE NOCASE
		NOT NULL,
	CHECK (lang_label <> ''))
STRICT;


-- Table: object
DROP TABLE IF EXISTS object;

CREATE TABLE object (
	object_id INTEGER
		NOT NULL
		PRIMARY KEY AUTOINCREMENT,
	code TEXT
		UNIQUE NOT NULL
		COLLATE NOCASE,
	CHECK (code <> ''))
STRICT;


-- Table: object_attribute
DROP TABLE IF EXISTS object_attribute;

CREATE TABLE object_attribute (
	object_id INTEGER,
	object_context_id INTEGER,
	attribute_id INTEGER,
	attr_context_id INTEGER,
	x INTEGER
		DEFAULT (1)
		NOT NULL,
	PRIMARY KEY (object_id, object_context_id, attribute_id, attr_context_id),
	FOREIGN KEY (object_id, object_context_id)
		REFERENCES object_context (object_id, context_id)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT
		DEFERRABLE INITIALLY DEFERRED,
	FOREIGN KEY (attribute_id, attr_context_id)
		REFERENCES attribute_context (attribute_id, context_id)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT
		DEFERRABLE INITIALLY DEFERRED,
	CHECK (object_context_id = attr_context_id),
	CHECK (x = 1))
STRICT;


-- Table: object_context
DROP TABLE IF EXISTS object_context;

CREATE TABLE object_context (
	object_id INTEGER
		REFERENCES object (object_id)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT
		DEFERRABLE INITIALLY DEFERRED,
	context_id INTEGER
		REFERENCES context (context_id)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT
		DEFERRABLE INITIALLY DEFERRED,
	PRIMARY KEY (object_id, context_id))
STRICT;


-- Table: object_desc
DROP TABLE IF EXISTS object_desc;

CREATE TABLE object_desc (
	object_id INTEGER
		REFERENCES object (object_id)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT
		DEFERRABLE INITIALLY DEFERRED,
	lang_code TEXT
		REFERENCES lang (lang_code)
		ON DELETE RESTRICT
		ON UPDATE RESTRICT
		DEFERRABLE INITIALLY DEFERRED,
	label TEXT
		NOT NULL
		COLLATE NOCASE,
	PRIMARY KEY (object_id, lang_code),
	UNIQUE (lang_code, label),
	CHECK (label <> ''))
STRICT;


-- View: v_attr_class_context
DROP VIEW IF EXISTS v_attr_class_context;

CREATE VIEW v_attr_class_context AS
SELECT
	attribute_desc.label AS attribute_label,
	attr_class.code AS class_code,
	context.code AS context_code
FROM
	attribute,
	attr_context_class,
	attribute_desc,
	attr_class,
	context,
	attribute_context
WHERE
	attribute.attribute_id = attr_context_class.attribute_id
	AND attr_context_class.attribute_id = attribute_desc.attribute_id
	AND attr_context_class.attr_class_id = attr_class.attr_class_id
	AND context.context_id = attribute_context.context_id
	AND attribute.attribute_id = attribute_context.attribute_id
;


-- View: v_attribute_classes
DROP VIEW IF EXISTS v_attribute_classes;

CREATE VIEW v_attribute_classes AS
SELECT
	ac.code AS Code,
	en.title AS Title_en,
	es.title AS Title_es
FROM
	attr_class AS ac
	LEFT JOIN attr_class_desc AS en
		ON ac.attr_class_id = en.attr_class_id
		AND en.lang_code = 'en'
	LEFT JOIN attr_class_desc AS es
		ON ac.attr_class_id = es.attr_class_id
		AND es.lang_code = 'es'
	ORDER BY
		ac.ord
;


-- View: v_attribute_context
DROP VIEW IF EXISTS v_attribute_context;

CREATE VIEW v_attribute_context AS
SELECT
	ad.lang_code AS Lang,
	d.code AS Context,
	ad.label AS Attribute
FROM
	attribute AS a
	NATURAL JOIN attribute_context
	NATURAL JOIN attribute_desc AS ad
	NATURAL JOIN context AS d
	NATURAL JOIN attr_context_class AS adc
ORDER BY
	Lang,
	Context
;


-- View: v_attributes
DROP VIEW IF EXISTS v_attributes;

CREATE VIEW v_attributes AS
SELECT
	ad.lang_code AS Lang,
	d.code AS Context,
	ac.code AS Class,
	ad.label AS Attribute,
	ad.title AS Title,
	a.formula AS Formula,
	ad.explanation AS Explanation,
	adc.reference AS Reference
FROM
	attribute AS a
	NATURAL JOIN attribute_context
	NATURAL JOIN attribute_desc AS ad
	NATURAL JOIN context AS d
	NATURAL JOIN attr_context_class AS adc
	JOIN attr_class AS ac USING (attr_class_id)
ORDER BY
	Lang,
	Context,
	Class
;


-- View: v_context_assignments
DROP VIEW IF EXISTS v_context_assignments;

CREATE VIEW v_context_assignments AS
SELECT
	contexts.Lang,
	contexts.Context,
	contexts.ObjectCode,
	contexts.Object,
	contexts.Attribute,
	contexts.Class,
	COALESCE(object_attribute.x, 0) AS x,
	object_attribute.object_id,
	object_attribute.attribute_id
FROM
	v_contexts AS contexts
	LEFT OUTER JOIN object_attribute
		ON contexts.object_id = object_attribute.object_id
	AND contexts.attribute_id = object_attribute.attribute_id
	AND contexts.context_id = object_attribute.object_context_id
ORDER BY
	contexts.Context ASC,
	contexts.Object ASC
;


-- View: v_context_class
DROP VIEW IF EXISTS v_context_class;

CREATE VIEW v_context_class AS
SELECT
	context_id,
	d.code AS context,
	dc.code AS class
FROM
	context AS d
	JOIN context_class AS dc USING (context_class_id)
;


-- View: v_contexts
DROP VIEW IF EXISTS v_contexts;

CREATE VIEW v_contexts AS
SELECT
	lang.lang_code AS Lang,
	context.code AS Context,
	object.code AS ObjectCode,
	object_desc.label AS Object,
	attribute_desc.label AS Attribute,
	attr_class.code AS Class,
	object_context.object_id,
	attribute_context.attribute_id,
	context.context_id
FROM
	lang,
	object,
	object_desc,
	attribute_desc,
	attr_context_class,
	attribute,
	attr_class,
	context,
	context_class,
	attribute_context,
	object_context
WHERE
	object.object_id = object_desc.object_id
	AND object_desc.lang_code = lang.lang_code
	AND attribute_desc.lang_code = lang.lang_code
	AND attribute.attribute_id = attr_context_class.attribute_id
	AND attr_context_class.attribute_id = attribute_desc.attribute_id
	AND attr_context_class.context_class_id = attribute_desc.context_class_id
	AND attr_context_class.attr_class_id = attr_class.attr_class_id
	AND attribute_context.attribute_id = attribute.attribute_id
	AND context_class.context_class_id = context.context_class_id
	AND context_class.context_class_id = attribute_desc.context_class_id
	AND context.context_id = attribute_context.context_id
	AND object_context.object_id = object_desc.object_id
	AND context.context_id = object_context.context_id
ORDER BY
	Lang ASC,
	Context ASC,
	Object ASC,
	Attribute ASC
;


-- View: v_object_context
DROP VIEW IF EXISTS v_object_context;

CREATE VIEW v_object_context AS
SELECT
	od.lang_code AS Lang,
	d.code AS Context,
	od.label AS Object,
	o.code AS Code
FROM
	object AS o
	NATURAL JOIN object_context
	NATURAL JOIN object_desc AS od
	JOIN context AS d USING (context_id)
ORDER BY
	Lang,
	Context
;


COMMIT TRANSACTION;
PRAGMA foreign_keys = on;

package persist

type Repository[Pk any, Record any] interface {
	Exists(Pk) bool

	Create(Record) error
	Read(Pk) Record
	ReadAll() []Record
	Update(Pk, Record) error
	Delete(Pk)
}

type Record[Pk any] interface {
	Pk() Pk
}

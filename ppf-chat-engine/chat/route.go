package chat

import (
	"encoding/json"
	"fmt"
)

type Route struct {
	Id         string  `json:"id"`
	Name       string  `json:"destinationAlias"`
	Driver     *User   `json:"driver"`
	Passengers []*User `json:"passengers"`
}

func (u *Route) UnmarshalJSON(data []byte) error {
	type Alias Route
	aux := &struct {
		Id         int     `json:"id"`
		Name       string  `json:"destinationAlias"`
		Driver     *User   `json:"driver"`
		Passengers []*User `json:"passengers"`
		*Alias
	}{
		Alias: (*Alias)(u),
	}
	if err := json.Unmarshal(data, &aux); err != nil {
		return err
	}
	u.Id = fmt.Sprintf("%d", aux.Id)
	u.Name = aux.Name
	u.Driver = aux.Driver
	u.Passengers = aux.Passengers
	return nil
}

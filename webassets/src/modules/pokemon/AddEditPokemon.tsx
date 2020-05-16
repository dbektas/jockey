import React, { Component } from "react";
import API from "@aws-amplify/api";
import { Button, FormGroup, FormControl, Modal, FormLabel, Spinner, Form, Dropdown, DropdownButton } from "react-bootstrap";
import { Redirect } from "react-router-dom";
import "./AddEditPokemon.css";

const emailRegex = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
const strengths = ["Fighting", "Flying", "Poison", "Ground", "Psychic", "Ice", "Dragon", "Fairy"]

interface AddEditPokemonProps {
  match: any;
  history: any;
}

interface AddEditPokemonState {
  isExistingPokemon: boolean;
  isLoading: boolean;
  isUpdating: boolean;
  isDeleting: boolean;
  pokemon: Pokemon;
  showDeleteModal: boolean;
  redirect: string;
}

interface Pokemon {
  uuId: string;
  pokemon_name: string;
  pokemon_email: string;
  pokemon_type: string;
  pokemon_strength: string;
  pokemon_desc: string;
}

export default class AddEditPokemon extends Component<AddEditPokemonProps, AddEditPokemonState> {
  constructor(props: AddEditPokemonProps) {
    super(props);

    this.state = {
      redirect: '',
      isExistingPokemon: false,
      isLoading: false,
      isUpdating: false,
      isDeleting: false,
      showDeleteModal: false,
      pokemon: {
        uuId: '',
        pokemon_name: '',
        pokemon_email: '',
        pokemon_type: 'fire',
        pokemon_strength: strengths[0],
        pokemon_desc: ''
      },
    };
  }

  componentDidMount() {
    const id = this.props.match.params.id;
    if (id) {
      this.getPokemon(id);
      this.setState({
        isExistingPokemon: true,
      });
    }

  }

  getPokemon(uuId: string) {
    this.setState({
      isLoading: true,
    });

    return API.get("pokemons", `/pokemons/${uuId}`, null).then((value: any) => {
      this.setState({
        isLoading: false,
        pokemon: {
          uuId: this.props.match.params.id,
          pokemon_name: value.pokemon_name,
          pokemon_email: value.pokemon_email,
          pokemon_type: value.pokemon_type,
          pokemon_strength: value.pokemon_strength,
          pokemon_desc: value.pokemon_desc
        }
      });
    });
  }

  validateForm = () => {
    return emailRegex.test(this.state.pokemon.pokemon_email.toLowerCase()) &&
    this.state.pokemon.pokemon_name.length >= 3 && 
    this.state.pokemon.pokemon_email.length >= 5;
  }

  handleChange = (event: any) => {
    const { id, value } = event.target;
    this.setState({
      pokemon: {
        ...this.state.pokemon,
        [id]: value
      }
    } as any);
  }

  handleTypeChange = (event: any) => {
    this.setState({
      pokemon: {
        ...this.state.pokemon,
        pokemon_type: event.target.value
      }
    } as any );
  }
  
  handleStrengthChange = (eventKey: any, event: any) => {
    this.setState({
      pokemon: {
        ...this.state.pokemon,
        pokemon_strength: strengths[eventKey]
      }
    } as any );
  }

  handleCancel = (event: any) => {
    this.setState({
      redirect: '/'
    });
  }

  handleSubmit = async (event: any) => {
    this.setState ({
      isUpdating: true,
    });
    event.preventDefault();
    this.state.isExistingPokemon ? this.updatePokemon() : this.savePokemon();
  }

  updatePokemon = () => {
    const { pokemon } = this.state;
    return API.put("pokemons", `/pokemons/${this.props.match.params.id}`, {
      body: {
        pokemon_name: pokemon.pokemon_name,
        pokemon_email: pokemon.pokemon_email,
        pokemon_type: pokemon.pokemon_type,
        pokemon_strength: pokemon.pokemon_strength,
        pokemon_desc: pokemon.pokemon_desc
      }
    }).then((value: any) => {
      this.setState({
        isUpdating: false,
        redirect: '/'
      });
    });
  }

  savePokemon = () => {
    const { pokemon } = this.state;
    return API.post("pokemons", "/pokemons", {
      body: {
        pokemon_name: pokemon.pokemon_name,
        pokemon_email: pokemon.pokemon_email,
        pokemon_type: pokemon.pokemon_type,
        pokemon_strength: pokemon.pokemon_strength,
        pokemon_desc: pokemon.pokemon_desc
      }
    }).then((value: any) => {
      this.setState({
        isUpdating: false,
        redirect: '/'
      });
    });
  }

  showDeleteModal = (shouldShow: boolean) => {
    this.setState({
      showDeleteModal: shouldShow
    });
  }

  handleDelete = (event: any) => {
    this.setState({
      isDeleting: true,
    })

    return API.del("pokemons", `/pokemons/${this.props.match.params.id}`, null).then((value: any) => {
      this.setState({
        isDeleting: false,
        showDeleteModal: false,
        redirect: '/'
      });
    });

  }

  deleteModal() {
    return (
      <Modal
        show={this.state.showDeleteModal}
        onHide={() => this.showDeleteModal(false)}
        container={this}
        aria-labelledby="contained-modal-title"
        id="contained-modal">
        <Modal.Header closeButton>
          <Modal.Title id="contained-modal-title">Remove a pokemon</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          Are you sure you don't need this pokemon?
        </Modal.Body>
        <Modal.Footer>
          <Button
            variant="danger"
            onClick={this.handleDelete}>
            {this.state.isDeleting ?
              <span><Spinner size="sm" animation="border" className="mr-2" />Removing</span> :
              <span>Remove</span>}
            </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    const { pokemon, isExistingPokemon, showDeleteModal, redirect } = this.state;

    if (redirect) {
      return <Redirect push to={redirect} />;
    }

    return (
      <div className="pokemon">
        {this.state.isLoading ? 
          <Spinner animation="border" className="center-spinner" /> : 

          <Form noValidate onSubmit={this.handleSubmit}>
            <div className="form-body">
              <FormGroup >
                <FormLabel>Pokemon name</FormLabel>
                <FormControl 
                  id="pokemon_name"
                  name="pokemon_name"
                  onChange={this.handleChange}
                  value={pokemon.pokemon_name}
                  minLength={3}
                  isValid={pokemon.pokemon_name.length > 0}
                  isInvalid={pokemon.pokemon_name.length !== 0 && pokemon.pokemon_name.length < 3}
                  placeholder="Enter a pokemon name.."
                  required />
                <FormControl.Feedback type="invalid">Must be minimum 3 characters</FormControl.Feedback>
              </FormGroup>

              <FormGroup >
                <FormLabel>Pokemon email</FormLabel>
                <FormControl 
                  id="pokemon_email"
                  name="pokemon_email"
                  onChange={this.handleChange}
                  value={pokemon.pokemon_email.toLowerCase()}
                  minLength={5}
                  isValid={emailRegex.test(pokemon.pokemon_email.toLowerCase())}
                  isInvalid={pokemon.pokemon_email.length !== 0 && !emailRegex.test(pokemon.pokemon_email.toLowerCase())}
                  placeholder="Enter a pokemon email address :P .."
                  required />
                <FormControl.Feedback type="invalid">Must be a valid email address</FormControl.Feedback>
              </FormGroup>

              <FormGroup >
                <FormLabel>Pokemon type</FormLabel>
                <Form.Check
                label="water"
                value={"water"}
                onChange={this.handleTypeChange}
                checked={this.state.pokemon.pokemon_type === "water"}
                type={"radio"}
                required />
              
                <Form.Check
                label="ground"
                value={"ground"}
                onChange={this.handleTypeChange}
                checked={this.state.pokemon.pokemon_type === "ground"}
                type={"radio"}
                required />

                <Form.Check
                label="flying"
                value={"flying"}
                onChange={this.handleTypeChange}
                checked={this.state.pokemon.pokemon_type === "flying"}
                type={"radio"}
                required />

                <Form.Check
                label="fire"
                value={"fire"}
                onChange={this.handleTypeChange}
                checked={this.state.pokemon.pokemon_type === "fire"}
                type={"radio"}
                required />
              </FormGroup>

              <FormGroup >
                <FormLabel>Pokemon strength</FormLabel>
                <DropdownButton 
                  id="pokemon_strength" 
                  title={this.state.pokemon.pokemon_strength}
                  onSelect={this.handleStrengthChange.bind(this)}
                  variant="primary"
                  key="right"
                  drop="right">
                    {strengths.map((strength, i) => (
                      <Dropdown.Item key={i} eventKey={i}>
                        {strength}
                      </Dropdown.Item>
                    ))}
                </DropdownButton>
              </FormGroup>

              <FormGroup >
                <FormLabel>Pokemon info</FormLabel>
                <FormControl 
                  id="pokemon_desc"
                  name="pokemon_desc"
                  onChange={this.handleChange}
                  value={pokemon.pokemon_desc}
                  minLength={3}
                  isValid={true}
                  placeholder="Enter more info about this pokemon.."
                  as="textarea"
                  required />
              </FormGroup>
            </div>

            {isExistingPokemon &&
              <Button
                variant="outline-danger"
                onClick={() => this.showDeleteModal(true)}>
                Remove
              </Button>}

            <Button
              variant="primary"
              type="submit"
              disabled={!this.validateForm()}
              className="float-right"
              onClick={this.handleSubmit}>
              {this.state.isUpdating ?
                <span><Spinner size="sm" animation="border" className="mr-2" />{isExistingPokemon ? 'Updating' : 'Creating'}</span> :
                <span>{isExistingPokemon ? 'Update pokemon' : 'Create pokemon'}</span>}
            </Button>

            <Button
              variant="link"
              onClick={this.handleCancel}
              className="float-right">
              Cancel
            </Button>
          </Form>}
        
        {showDeleteModal && this.deleteModal()}
        
      </div>
    );
  }
}
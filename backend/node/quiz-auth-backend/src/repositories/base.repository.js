// simple base helpers - expand as needed
class BaseRepository {
    constructor(model) {
        this.model = model;
    }

    async create(doc) {
        return this.model.create(doc);
    }

    async findById(id) {
        return this.model.findById(id);
    }

    async findOne(filter) {
        return this.model.findOne(filter);
    }

    async updateOne(filter, update, opts = {}) {
        return this.model.updateOne(filter, update, opts);
    }

    async find(filter, projection = null, opts = {}) {
        return this.model.find(filter, projection, opts);
    }
}

module.exports = BaseRepository;